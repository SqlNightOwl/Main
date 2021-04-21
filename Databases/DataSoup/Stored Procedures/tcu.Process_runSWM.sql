use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_runSWM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_runSWM]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_runSWM
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	09/24/2007
Purpose  :	Control mechanism for generating SWIM II file request from the process
			table.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@detail		varchar(4000)
,	@process	sysname
,	@result		smallint
,	@started	datetime
,	@type		char(3)

--	collect the handler name and initialize some variables
select	@process	= ProcessHandler
	,	@detail		= ''
	,	@result		= 0
	,	@started	= getdate()
from	tcu.Process
where	ProcessId	= @ProcessId;

--	retrive the Process type for the handler
exec tcu.Process_checkProcessType	@process
								,	@type out;
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
else	--	unknown process handler
begin
	select	@detail	= 'An unknonw Process Handler "' + @process + '" was provided.'
		,	@result	= 1;
end;

--	build the SWIM file if executing the handler was sucessfull.
if @result = 0
begin
	exec @result = tcu.ProcessSwimDetail_buildSwimFile	@RunId		= @RunId
													,	@ProcessId	= @ProcessId
													,	@ScheduleId	= @ScheduleId
													,	@overRide	 = 0;
end;

--	log the execution...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= @started
					,	@Result		= @result
					,	@Command	= @process
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO