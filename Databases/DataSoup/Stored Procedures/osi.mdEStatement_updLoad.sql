use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdEStatement_updLoad]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[mdEStatement_updLoad]
GO
setuser N'osi'
GO
CREATE procedure osi.mdEStatement_updLoad
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/19/2007
Purpose  :	Updates the md_eStatement table after it's loaded and generates an
			update script for OSI to maintain the "EST" UserField for Persons
			and Organizations.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/18/2008	Vivian Liu		Modify the code to properly handle re-signed and 
							existing Member with eStatment.   For 'Drop' action, 
							the user files will be deleted the from OSI.
05/05/2008	Paul Hunter		Changed to accept Process variables and export file
							via BCP.
05/26/2009	Paul Hunter		Changed to run for "current month".
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(1000)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileOn		char(7)
,	@period		int
,	@result		int;

--	table to hold the net changes for this period
declare	@activity		table
(	MemberNumber	bigint primary key
,	Action			varchar(8)	not null
);

--	initialize variables...
select	@fileOn	= convert(char(7), getdate(), 121)
	,	@period	= cast(convert(char(6), getdate(), 112) as int);

--	collect the "net" changes to the data:
--	* if they are in this file and not the last one then they were added
--	* if they are in the table and not in the file then they dropped
insert	@activity
	(	MemberNumber
	,	Action
	)
select	MemberNumber	=	isnull(p.MemberNumber, c.MemberNumber)
	,	Action			=	case isnull(p.MemberNumber, 0)
							when 0 then 'add'
							else 'drop' end
from(	-- return enrolled member so the unEnrolled member 
		-- can be added again for the case of re-signed
		select	MemberNumber
		from	osi.mdEStatement
		where	Period			< @period
		and		UnEnrollPeriod	= 0
	)	p
full outer join
	(	select	MemberNumber
		from	osi.mdEStatement
		where	Period	= @period
	)	c	on	p.MemberNumber = c.MemberNumber
where	p.MemberNumber is null
	or	c.MemberNumber is null;

--	update members that "unenrolled" this period
update	e
set		UnEnrollPeriod	= @period
from	osi.mdEStatement	e
join	@activity			a
		on	e.MemberNumber = a.MemberNumber
where	a.Action = 'drop';

--	update members that signed up for eStatements again by keeping the record from
--	the current period and removing the prior record.
update	e
set		UnEnrollPeriod = -1
from	osi.mdEStatement	e
join(	select	MemberNumber
			,	Period
		from	osi.mdEStatement
		where	Period	= @period
	)	c	on	e.MemberNumber	= c.MemberNumber
			and	e.Period		< c.Period
where	e.UnEnrollPeriod > 0;

--	Keep Members that have already signed up for with eStatements and delete the newly loaded records.
update	c
set		UnEnrollPeriod = -1
from	osi.mdEStatement	c
join(	--	collect members with two records in the table
		select	MemberNumber
		from	osi.mdEStatement
		where	UnEnrollPeriod = 0
		group by MemberNumber
		having count(MemberNumber) > 1
	)	e	on	c.MemberNumber	= e.MemberNumber
			and	c.Period		= @period
where	c.UnEnrollPeriod = 0;

--	remove the records where the UnEnrollPeriod equals -1 (drop)
delete	osi.mdEStatement
where	UnEnrollPeriod = -1;

select	@actionCmd	= 'select script = case e.Period '
					+ 'when ' + cast(@period as varchar) + ' '
					+ 'then ''insert into osiBank.'' + o.CustomerType + ''USERFIELD ('' '
					+ '+ o.CustomerType + ''NBR, UserFieldCd, Value, DateLastMaint) '
					+ 'values ('' + o.CustomerId + '', ''''EST'''', ''''Y'''', sysdate)'' '
					+ 'else ''delete osiBank.'' + o.CustomerType + ''USERFIELD where '' '
					+ '+ o.CustomerType + ''NBR = '' + o.CustomerId '
					+ '+ '' and UserFieldCd = ''''EST'''''' '
					+ 'end + '';'' from '
					+ db_name() + '.osi.mdEStatement e '
					+ 'join openquery(OSI,'
					+ '''select MemberAgreeNbr'
					+ ', rtrim(CustomerType) as CustomerType'
					+ ', cast(CustomerId as varchar(22)) as CustomerId '
					+ 'from texans.CustomerMemberAgreement_vw'''
					+ ') o on e.MemberNumber = o.MemberAgreeNbr '
					+ 'where (e.Period = ' + cast(@period as varchar)
					+ ' or e.UnEnrollPeriod = ' + cast(@period as varchar) + ') '
					+ 'order by e.Period, o.CustomerType, o.CustomerId'
	,	@actionFile	= p.SQLFolder + replace(f.TargetFile, '[PERIOD]', @fileOn)
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	p.ProcessId = f.ProcessId
where	f.ProcessId	= @ProcessId;

--	export the insert/update script to be executed against OSI.
exec @result = tcu.File_bcp	@action		= 'queryout'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -T'
						,	@output		= @detail output;

--	report any errors
if @result != 0 or len(@detail) > 0
begin
	set	@result	= 1;	--	failure
	set	@detail	= @actionCmd + char(13) + char(10) + @detail;
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO