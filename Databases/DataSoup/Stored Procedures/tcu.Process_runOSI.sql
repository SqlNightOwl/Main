use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_runOSI]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_runOSI]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_runOSI
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	09/24/2007
Purpose  :	Control mechanism for executing OSI Process from the Process table.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/05/2007	Paul Hunter		Changed the procedure to use the ProcessOSILog
							table/procedure which indicates if the OSI appl(s)
							have all completed.
03/10/2010	Paul Hunter		Added table clean up routine.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@detail		varchar(4000)
,	@handler	sysname
,	@isReady	bit
,	@process	varchar(50)
,	@result		int
,	@retention	int
,	@startedOn	datetime
,	@type		char(3);

--	intialize processing variables
select	@process	= Process
	,	@type		= ProcessType
	,	@handler	= ProcessHandler
	,	@detail		= ''
	,	@startedOn	= getdate()
	,	@result		= 0
from	tcu.Process
where	@ProcessId	= ProcessId;

--	determine the status of the process
exec tcu.ProcessOSILog_ins	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@IsReady 	= @isReady	output;

--	keep on trucking if the OSI applications are complete!
if @isReady = 1
begin

	--	determine the process type based on the handler...
	exec tcu.Process_checkProcessType @handler, @type output;

	--	...execute the handler base on the type
	if @type = 'DTS'
	begin
		exec @result = tcu.Process_runDTS	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;
	end;
	else if @type = 'PRC'
	begin
		exec @result = tcu.Process_runPRC	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;
	end;
	else if @type	 = 'n/a'
		and @handler is null
	begin
		--	no handler was provided, so just copy the file(s)
		exec @result = tcu.ProcessOSI_copyFiles	@RunId		= @RunId
											,	@ProcessId	= @ProcessId
											,	@ScheduleId	= @ScheduleId;
	end;
	else
	begin
		--	a handler was provided but it couldn't be found,
		--	so record that and generate an appropriate error message.
		select	@result	= 1		--	failure
			,	@detail	= 'The handler "' + @handler + '" for the process "'
						+ @process + '" could not be found.';

	end;	--	failed to find the handler
end;
else
begin
	select	@result	= 2		--	information
		,	@detail	= 'Not all of the OSI Applications have completed generating files for the process "'
					+ @process + '".<br/>If you believe that the applications have completed then there '
					+ 'may be another issue that needs to be resolved.';
end;

set	@retention = isnull(cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int), 30) * -1;

--	clean the log table based on the retention period
delete	tcu.ProcessOSILog
where	ProcessId	= @ProcessId
and		EffectiveOn	< dateadd(day, @retention, convert(char(10), @startedOn, 101));

--	record the fact that the process ran...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= @startedOn
					,	@Result		= @result
					,	@Command	= @handler
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO