use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetail_exportFiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[IrsDetail_exportFiles]
GO
setuser N'osi'
GO
CREATE procedure osi.IrsDetail_exportFiles
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/16/2007
Purpose  :	Process for creating the IRS files to send to both MicroDynamics and
			NCP for printing.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		varchar(255)
,	@cmdTCC		varchar(255)
,	@crlf		char(2)
,	@dataSource	sysname
,	@detail		varchar(4000)
,	@exclude	varchar(25)
,	@fileName	varchar(25)
,	@folder		varchar(255)
,	@message	varchar(255)
,	@proc		varchar(255)
,	@reportId	char(1)
,	@result		int
,	@started	datetime
,	@targetFile	varchar(255)
,	@targetTCC	varchar(255);

select	@dataSource	= db_name() + '.osi.IrsDetail_v'
	,	@crlf		= char(13) + char(10)
	,	@proc		= db_name() + '.' + object_name(@@procid)
	,	@reportId	= ''
	,	@result		= 0;

--	retrieve the bcp export folder
select	@folder	= tcu.fn_SQLFolder('\' + Value + '\')
from	tcu.ProcessParameter
where	ProcessId	= @ProcessId
and		Parameter	= 'Folder Offset';

--	collect the excluded file attribute
select	@exclude	= FileName
from	osi.IrsReport
where	IrsReportId = '+';

--	clean out the TTC Accounts and reload them from CORE
truncate table osi.IrsDetailTCC;

insert	osi.IrsDetailTCC
	(	AccountNumber	)
select	AcctNbr
from	openquery(OSI,'select AcctNbr from osiBank.Acct where BranchOrgNbr = 300');

exec sp_refreshview @dataSource;

--	loop thru the IRS Report table and build the command to export those records
while exists (	select	top 1 FileName from osi.IrsReport
				where	IrsReportId	>	@reportId
				and		FileName	!=	@exclude	)
begin
	select	top 1
			@reportId	= IrsReportId
		,	@cmd		= 'select Detail from ' + @dataSource
						+ ' where ((IrsReportId = ''' + IrsReportId + ''') and IsTCCAccount = 0)'
						+ ' or IrsReportId = ''+'' order by RowId'
		,	@targetFile	= @folder + FileName
		,	@cmdTCC		= 'select Detail from ' + @dataSource
						+ ' where ((IrsReportId = ''' + IrsReportId + ''') and IsTCCAccount = 1)'
						+ ' or IrsReportId = ''+'' order by RowId'
		,	@targetTCC	= @folder + IrsReport + '.tcc'
	from	osi.IrsReport
	where	IrsReportId	>	@reportId
	and		FileName	!=	@exclude
	order by IrsReportId;

	--	if there are records in the detail table then export them
	if exists (	select	top 1 IrsReportId from osi.IrsDetail_v
				where	IrsReportId		= @reportId
				and		IsTCCAccount	= 0	)
	begin
		set	@started = getdate();

		--	export the Texans file first...
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @cmd
								,	@actionFile	= @targetFile
								,	@switches	= '-c -T'
								,	@output		= @detail	output;

		--	and the TCC file next...
		if	@result = 0
		and	exists (select	top 1 IrsReportId from osi.IrsDetail_v
					where	IrsReportId		= @reportId
					and		IsTCCAccount	= 1	)
			exec @result = tcu.File_bcp	@action		= 'queryout'
									,	@actionCmd	= @cmdTCC
									,	@actionFile	= @targetTCC
									,	@switches	= '-c -T'
									,	@output		= @detail	output;

		--	if not sucessfull...
		if @result != 0
		begin
			set	@result	= 1;
			set	@cmd	= @cmd + @crlf 
						+ 'Failed with this resulx...' + @crlf
						+ isnull(@detail, 'No detail provided.');

			--	send notification if not sucessfull and list it as a failure...
			exec tcu.ProcessNotification_send	@ProcessId	= @ProcessId
											,	@Result		= @result
											,	@Details	= @cmd;
		end;

		--	log the results of the execution regardless of the results.
		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= @started
							,	@Result		= @result
							,	@Command	= @proc
							,	@Message	= @cmd;
	end;

end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO