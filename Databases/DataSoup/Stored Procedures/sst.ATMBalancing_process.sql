use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancing_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[ATMBalancing_process]
GO
setuser N'sst'
GO
CREATE procedure sst.ATMBalancing_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/20/2009
Purpose  :	Loads the CNS TS10 file and extracts ATM Withdrawal information so
			that it can be converted into a SWIM file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileId		int
,	@fileName	varchar(50)
,	@ftpFolder	varchar(255)
,	@reportOn	char(10)
,	@result		int
,	@retention	int
,	@run		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(50)

--	initialize the variables...
select	@actionCmd	= db_name() + '.sst.ATMBalancing'
	,	@fileName	= f.FileName
	,	@ftpFolder	= p.FTPFolder
	,	@sqlFolder	= p.SQLFolder
	,	@targetFile	= f.TargetFile
	,	@retention	= p.RetentionPeriod
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + p.FormatFile) + '" -T'
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
	,	@run		= @RunId	--	there may be multiple files so each will be loaded with a different RunId
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	see if there is are any files available for loading...
exec @result = tcu.FileLog_findFiles	@ProcessId			= @ProcessId
									,	@RunId				= @RunId
									,	@uncFolder			= @ftpFolder
									,	@fileMask			= @fileName
									,	@includeSubFolders	= 0;

--	load each file in turn...
while exists (	select	top 1 * from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin

	select	top 1
			@actionFile	= Path + '\' + FileName
		,	@fileId		= FileId
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	order by FileId;

	--	clear and reindex the staging table...
	truncate table sst.ATMBalancing;
	alter index all on sst.ATMBalancing rebuild;

	--	load the file
	exec @result = tcu.file_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;
	--	report errors...
	if len(@detail) > 0 or @result != 0
	begin
		set	@result	= 1;	--	failure
		break;
	end;
	else
	begin
		--	if the file hasn't been loaded then load them into the permanent table...
		if exists (	select top 1 Record from sst.ATMBalancing )
		begin
			--	get the report date...
			select	@reportOn = convert(char(10), cast(substring(Record, charindex('FOR', Record) + 4, 255) as datetime), 121)
			from	sst.ATMBalancing
			where	RowId = 3;

			if not exists(	select	top 1 Terminal from sst.ATMBalancingLog
							where	ReportOn = @reportOn )
			begin
				insert	sst.ATMBalancingLog
					(	ReportOn
					,	Terminal
					,	Withdrawal
					,	Fee
					,	NetWithdrawal
					,	DepositSave
					,	DepositCheck
					,	DepositCrCard
					,	DepositCrLine
					,	Deposit
					)
				select	ReportOn
					,	Terminal
					,	Withdrawal
					,	Fee
					,	NetWithdrawal
					,	DepositSave
					,	DepositCheck
					,	DepositCrCard
					,	DepositCrLine
					,	Deposit
				from	sst.ATMBalancing_vDetail
				order by Terminal;

				--	generate the SWIM file...
				exec @result = sst.ATMBalancing_savWithdrawalSWIM	@RunId		= @run
																,	@ProcessId	= @ProcessId
																,	@ScheduleId	= @ScheduleId;

				--	generate the ATM check file...
				select	@actionCmd	= 'select * from ' + db_name() + '.sst.ATMBalancingLog_vReport '
									+ 'where (ReportOn = ''' + @reportOn
									+ ''' or ReportOn = ''Report On'') '
									+ ' order by Terminal;'
					,	@actionFile	= @SQLFolder + replace(replace(@targetFile, '.', '-' + @reportOn + '.'), 'SWM', 'csv')
					,	@run		= @run + 1
					,	@switches	= '-c -t, -T';

				exec @result = tcu.file_bcp	@action		= 'queryout'
										,	@actionCmd	= @actionCmd
										,	@actionFile	= @actionFile
										,	@switches	= @switches
										,	@output		= @detail output;

				if len(@detail) > 0 or @result != 0
				begin
					set	@result	= 1;	--	failure
					break;
				end;
			end;		--	no records loaded -- so load...
		end;
	end;
end;

--	remove old data...
delete	sst.ATMBalancingLog
where	ReportOn < dateadd(day, @retention, getdate())

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