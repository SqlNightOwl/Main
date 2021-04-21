use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[NewMemberOnBoard_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[NewMemberOnBoard_process]
GO
setuser N'osi'
GO
CREATE procedure osi.NewMemberOnBoard_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	04/22/2008
Purpose  :	Provides an export of new and closed accounts for the Texans New
			Member On-Boarding process.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int

truncate table osi.NewMemberOnBoard;

insert	osi.NewMemberOnBoard
select	tcu.fn_ZeroPad(AcctNbr		, 20)
	,	tcu.fn_ZeroPad(BranchNumber	, 5)
	,	isnull(left(Name			, 50)	, '')
	,	isnull(left(Address			, 50)	, '')
	,	isnull(left(CityName		, 30)	, '')
	,	isnull(left(StateCd			, 2)	, '')
	,	isnull(left(ZipCd			, 9)	, '')
	,	isnull(left(Phone			, 10)	, '')
	,	isnull(left(EmailAddress	, 100)	, '')
	,	isnull(left(EmployeeFlag	, 1)	, '')
	,	isnull(left(ForeignFlag		, 1)	, '')
	,	isnull(left(AccountStatus	, 1)	, '')
	,	isnull(left(ContractDate	, 10)	, '')
	,	isnull(left(CloseDate		, 10)	, '')
	,	isnull(left(DoNotMail 		, 1)	, '')
	,	isnull(left(CurrMiAcctTypCd	, 6)	, '')
	,	right('0' + len(cast(AcctNbr as varchar(20))), 2)
from	openquery(OSI,'
		select	AcctNbr
			,	BranchNumber
			,	Name
			,	Address
			,	CityName
			,	StateCd
			,	ZipCd
			,	Phone
			,	EmailAddress
			,	EmployeeFlag
			,	ForeignFlag
			,	AccountStatus
			,	ContractDate
			,	CloseDate
			,	DoNotMail
			,	CurrMiAcctTypCd
		from	texans.NewMemberOnBoard_vw');

--	initialize the parameters...
select	@actionCmd	= 'select Record from ' + db_name() + '.' + f.FileName
					+ ' where ProcessId = ' + cast(p.ProcessId as varchar)
					+ ' order by rowType'
	,	@actionFile	= p.FTPFolder
					+ replace(f.TargetFile, '[DATE]', replace(convert(varchar, getdate(), 10), '-', ''))
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	p.ProcessId	= @ProcessId;

--	check to see if there are accounts to export...
if exists (	select top 1 * from osi.NewMemberOnBoard )
begin
	--	export the file...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	-- increment the file sequence number...
	if @result = 0 and len(@detail) = 0
	begin
		update	tcu.ProcessParameter	
		set		Value		= cast(Value as int) + 1 
		where	ProcessId	= @ProcessId
		and		Parameter	= 'File Sequence Number';
	end;
	else	--	report any errors...
	begin
		set	@result = 3;	--	warning
	end;
end;
else
begin
	select	@result		= 2	--	information
		,	@actionCmd	= 'select count(1) from OSI..texans.NewMemberOnBoard_vw'
		,	@detail		= 'No accounts were opened or closed for the week ending '
						+ convert(varchar, getdate(), 101) + '.';
end

--	record any errors...
if @result != 0 or len(@detail) > 0
begin
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