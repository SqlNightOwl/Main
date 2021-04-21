use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[NetLend_getPrefill]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[NetLend_getPrefill]
GO
setuser N'lnd'
GO
CREATE procedure lnd.NetLend_getPrefill
	@MemberNumber	bigint
,	@SSN			varchar(11)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	10/31/2006
Purpose  :	Enables searching on the Member table for Netlend Prefill.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/28/2007	Biju Basheer	Modified to use OSI instead of Premier.
08/17/2007	Paul Hunter		Added logging of member requests.
03/11/2008	Paul Hunter		Changed OSI query to use openquery syntax instead of
							[DB]..[schema].[object] syntax.
05/29/2008	Paul Hunter		Removed the temp table, changed the logic to use the
							PersNbr and attempts inside the openquery OSI query
							and the SSN on the returned data.
10/21/2008	Paul Hunter		Changed query to use raw TaxId for the lookup as it
							provides better performance.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
03/12/2010	Paul Hunter		Changed Lock Out period from 24 to 12 hours.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@attempts	int
,	@cmd		nvarchar(1000)
,	@lockHours	int
,	@lockTries	int
,	@success	bit

--	initialize variables and
select	@lockHours	= 12 * -1 --	(you're looking back)
	,	@lockTries	= 6
	--	Clean up the SSN
	,	@SSN		= left(isnull(ltrim(rtrim(replace(@SSN, '-', ''))), ''), 9);

--	count the max number of attempts made with this data including this run
select	@attempts	= max(items)
from(	select	items = count(1) + 1
		from	lnd.NetLendLog
		where (	MemberNumber	= @MemberNumber
			or	SSN				= @SSN	)
		and		RecordedOn		> dateadd(hour, @lockHours, getdate())
	)	attempt;

--	setup the command to be executed
set @cmd = '
select	MemberNumber
	,	FirstName
	,	MiddleName
	,	LastName
	,	Address1
	,	Address2
	,	City
	,	State
	,	Zip	= isnull(Zip, ''0'')
	,	PrimaryPhone
	,	SSN	= ''' + @SSN + '''
	,	Birthdate
	,	Suffix
from	openquery(OSI,  ''
select	MemberNumber
	,	FirstName
	,	MiddleName
	,	LastName
	,	Address1
	,	Address2
	,	City
	,	State
	,	Zip
	,	PrimaryPhone
	,	nvl(Birthdate, ''''01/01/1900'''') as Birthdate
	,	Suffix
	,	PersNbr
from	texans.NetLendPreFill_vw
where	MemberNumber = ' + cast(@MemberNumber as varchar) + '
and		TaxId = osiBank.pack_TaxId.func_SetTaxId(''''' + @SSN + ''''', null)
and		' + cast(@attempts as varchar) + ' < ' + cast(@lockTries as varchar(10)) + ''')';

exec sp_executesql @cmd;

--	record the request
set	@success = case @@rowcount when 0 then 0 else 1 end;

exec lnd.NetLendLog_ins @MemberNumber, @SSN, @success;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [lnd].[NetLend_getPrefill]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [lnd].[NetLend_getPrefill]  TO [wa_Services]
GO
GRANT  EXECUTE  ON [lnd].[NetLend_getPrefill]  TO [wa_Lending]
GO