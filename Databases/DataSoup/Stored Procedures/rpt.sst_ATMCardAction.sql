use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[sst_ATMCardAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[sst_ATMCardAction]
GO
setuser N'rpt'
GO
create procedure rpt.sst_ATMCardAction
	@ExpiresOn	datetime
,	@ssrsUser	varchar(25)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/02/2010
Purpose  :	Retrieves ATM Cards and any Debit card connected by Person & Account.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(600)
,	@return	int

set	@ssrsUser = substring(@ssrsUser, charindex('\', @ssrsUser) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @ssrsUser;

set	@cmd = '
select	ATMCardNbr
	,	ATMLastTranDate
	,	CardHolderName
	,	Age
	,	MemberAgreeNbr
	,	PrimaryChecking
	,	PrimarySavings
	,	Address1
	,	Address2
	,	CityName
	,	StateCd
	,	ZipCd
	,	AcctNbr
	,	AcctAction
from	openquery(OSI, ''
		select	ATMCardNbr
			,	ATMLastTranDate
			,	CardHolderName
			,	Age
			,	MemberAgreeNbr
			,	PrimaryChecking
			,	PrimarySavings
			,	Address1
			,	Address2
			,	CityName
			,	StateCd
			,	ZipCd
			,	AcctNbr
			,	AcctAction
		from	texans.sst_ATMCardAction_vw
		where	ATMExpireDate = to_date(''''' + convert(char(10), @ExpiresOn, 101) + ''''', ''''mm/dd/yyyy'''')'');'

exec sp_executesql @cmd;

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO