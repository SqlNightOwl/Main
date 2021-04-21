use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessQue_execute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessQue_execute]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessQue_execute
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/13/2010
Purpose  :	Control mechanism for executing items from the scheduled Task List.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/05/2010	Paul Hunter		Added ProcessLog retention policy.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@category		varchar(20)
,	@detail			varchar(4000)
,	@finshed		datetime
,	@isManual		bit
,	@processId		smallint
,	@processQueId	int
,	@processType	char(3)
,	@result			int
,	@retention		int
,	@row			int
,	@runId			int
,	@scheduleId		tinyint
,	@started		datetime
,	@user			varchar(25)

begin try
	--	retrieve the next queued scheduled process...
	exec @processQueId = tcu.ProcessQue_getNextScheduledProcess;

	while @processQueId != 0
	begin
		--	a Process Que Id was returned
		if @processQueId > 0
		begin
			--	get the process information...
			select	@isManual		= IsManualRun
				,	@runId			= RunId
				,	@processId		= ProcessId
				,	@scheduleId		= ScheduleId
				,	@processType	= ProcessType
				,	@category		= Category
				,	@started		= StartedOn
				,	@detail			= ''
				,	@result			= 0
			from	tcu.ProcessQue
			where	ProcessQueId	= @ProcessQueId;

		--	future use
		-- 	if @processType = 'ACH'
		-- 		print 'exec @result = tcu.Process_runACH @runId, @ProcessId, @ScheduleId;'

			if @processType = 'DTS'
				exec @result = tcu.Process_runDTS @runId, @ProcessId, @ScheduleId;

		--	future use
		-- 	if @processType = 'FTP'
		-- 		print 'exec @result = tcu.Process_runFTP @runId, @ProcessId, @ScheduleId;'

			if @processType = 'OSI'
				exec @result = tcu.Process_runOSI @runId, @ProcessId, @ScheduleId;

			if @processType = 'PRC'
				exec @result = tcu.Process_runPRC @runId, @ProcessId, @ScheduleId;

			if @processType = 'SWM'
				exec @result = tcu.Process_runSWM @runId, @ProcessId, @ScheduleId;

			--	retrieve any messages...
			select	@detail		= isnull(Message, '')
				,	@finshed	= getdate()
			from	tcu.ProcessLog
			where	RunId		= @runId
			and		ProcessId	= @ProcessId
			and		ScheduleId	= @ScheduleId;

			--	send notifications....
			exec tcu.ProcessNotification_send	@ProcessId	= @ProcessId
											,	@Result		= @result
											,	@Details	= @detail;

			--	disabled "on demand" processes after they're run...
			if @category = 'On Demand'
			begin
				update	tcu.Process
				set		IsEnabled	= 0
					,	UpdatedBy	= @user
					,	UpdatedOn	= @finshed
				where	ProcessId	= @ProcessId;
			end;

			--	update the ProcessLog with the actual start/finish times...
			update	tcu.ProcessLog
			set		StartedOn	= @started
				,	FinishedOn	= @finshed
			where	RunId		= @runId
			and		ProcessId	= @ProcessId
			and		ScheduleId	= @ScheduleId;

			--	collect the retention period...
			set	@retention = isnull(cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int), 30) * -1;

			--	clean the log table based on the retention period
			delete	tcu.ProcessLog
			where	ProcessId	= @ProcessId
			and		CreatedOn	< dateadd(day, @retention, convert(char(10), @finshed, 101));

			--	return the results if it's a manual request.
			if @isManual = 1
			begin
				select	isnull(@user, 'SQL Job') as Requestor
					,	*
				from	tcu.ProcessLog_vResults
				where	RunId		= @runId
				and		ProcessId	= @ProcessId
				and		ScheduleId	= @ScheduleId;
			end;

			--	remove the record from tcu.ProcessQue table...
			delete	tcu.ProcessQue
			where	ProcessQueId = @ProcessQueId;

		end;	--	process execution...

		--	retrieve the next available queued process...
		exec @processQueId = tcu.ProcessQue_getNextScheduledProcess;

	end;		--	while loop
end try
begin catch
	-- catch any unhandled exceptions...  
	exec tcu.ErrorDetail_get @detail out;

	exec tcu.Email_send	@subject		= 'ERROR in tcu.ProcessQue_execute'
					,	@message		= @detail
					,	@sendTo			= null
					,	@sendCC			= null
					,	@asHtml			= 1
					,	@attachedFiles	= null;
	return 1;
end catch;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO