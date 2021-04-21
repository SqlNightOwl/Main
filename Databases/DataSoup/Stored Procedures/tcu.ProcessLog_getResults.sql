use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessLog_getResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessLog_getResults]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessLog_getResults
	@ProcessId		smallint	= null
,	@ScheduleId		tinyint		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	02/15/2008
Purpose  :	Retrieves record(s) from the ProcessLog_vResults table .
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	ProcessLogId
	,	RunId
	,	ProcessId
	,	Process
	,	ScheduleId
	,	StartedOn
	,	FinishedOn
	,	Result
	,	RunTime
	,	Command
	,	Message
	,	RunOn
from	tcu.ProcessLog_vResults
where 	ProcessId 	= isnull(@ProcessId, ProcessId)
and		ScheduleId	= isnull(@ScheduleId, ScheduleId)
and		StartedOn 	in(	select	max(StartedOn)
						from	tcu.ProcessLog
						group by ProcessId
						having  ProcessId = isnull(@ProcessId, ProcessId))
order by
		RunId
	,	ProcessLogId
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[ProcessLog_getResults]  TO [wa_Process]
GO