use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessLog_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessLog_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessLog_sav
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
,	@StartedOn	datetime
,	@Result		tinyint
,	@Command	varchar(255)
,	@Message	varchar(4000)
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	09/24/2007
Purpose  :	Inserts a record in the ProcessLog table.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/28/2008	Paul Hunter		Changed procedure over to an upsert and renamed the
							from ProcessLog_ins to ProcessLog_sav
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@id		int
,	@lenCmd	int
,	@lenMsg	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	retrieve the maximum length of the command and message strings.
set	@id			= object_id('tcu.ProcessLog')
set	@lenCmd		= columnproperty(@id, 'Command', 'Precision')
set	@lenMsg		= columnproperty(@id, 'Message', 'Precision')

--	standardize the Result, Command and Message parameters
set	@Result		= nullif(@Result, 0)
set	@StartedOn	= isnull(@StartedOn, getdate())
set	@Command	= nullif(isnull(rtrim(@Command), ''), '')
set	@Message	= nullif(isnull(rtrim(@Message), ''), '')

--	try an update for other executions for this Run, Process and Schedule.
update	tcu.ProcessLog
set		StartedOn		= case when @StartedOn < StartedOn then @StartedOn else StartedOn end
	,	FinishedOn		= getdate()
	,	Result			= isnull(@Result, Result)
	,	Command			= left(	case	--	add this Command to the front if this was started earlier then the existing record otherwise add it to the end
								when @StartedOn < StartedOn
									then isnull(@Command + ' ~ ', '') + Command
								else Command + isnull(' ~ ' + @Command, '')
								end, @lenCmd)
	,	Message			= left(	case	--	add this Message to the front if this was started earlier then the existing record otherwise add it to the end
								when @StartedOn < StartedOn
									then isnull(@Message + ' ~ ', '') + Message
								else Message + isnull(' ~ ' + @Message, '')
								end, @lenMsg)
where	RunId		= @RunId
and		ProcessId	= @ProcessId
and		ScheduleId	= @ScheduleId

--	no record affected so do the insert
if @@rowcount = 0
begin
	insert	tcu.ProcessLog
		(	RunId
		,	ProcessId
		,	ScheduleId
		,	StartedOn
		,	FinishedOn
		,	Result
		,	Command
		,	Message
		,	CreatedOn
		,	CreatedBy
		)
	values
		(	@RunId
		,	@ProcessId
		,	@ScheduleId
		,	@StartedOn
		,	getdate()		--	FinishedOn
		,	isnull(@Result, 0)
		,	isnull(@Command, '')
		,	isnull(@Message, '')
		,	getdate()		--	CreatedOn
		,	tcu.fn_UserAudit()
		)
end

set	@error = @@error

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @errmsg) with log
end

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO