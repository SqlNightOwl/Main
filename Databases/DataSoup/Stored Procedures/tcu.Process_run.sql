use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_run]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_run]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_run
	@ProcessId	smallint	= null
,	@ScheduleId	tinyint		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/20/2007
Purpose  :	Control mechanism for scheduleing and executing Texans Processes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/05/2008	Paul Hunter		Added retrieving/sending notifications to the process
							so that reporting may be centralized.
06/23/2008	Paul Hunter		Added code to disable "On Demand" processes.
07/01/2009	Paul Hunter		Changed from using a table variable to the static
							table tcu.ProcessQue to aid in troubleshooting
							hung processes...
12/01/2009	Paul Hunter		Changed  the method for getting the RunId to use the
							procedure tcu.Process_getNextRunId which pulls and
							increments a value from the Dictionary.
02/13/2010	Paul Hunter		Created seperate procedure to schedule processes.
							Created seperate execution procedure so the process
							can support multiple job schedules.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

--	load the que with the scheduled or requested processes...
exec tcu.ProcessQue_loadSchedule @ProcessId, @ScheduleId;

--	call the first/initial execution of this Process executor...
exec tcu.ProcessQue_execute;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Process_run]  TO [wa_Process]
GO