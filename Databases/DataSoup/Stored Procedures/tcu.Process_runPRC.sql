use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_runPRC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_runPRC]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_runPRC
	@runId				int
,	@processId			smallint
,	@scheduleId			tinyint
,	@AlternateHandler	sysname		= null	--	handler to use if not from the process
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/20/2007
Purpose  :	Control mechanism for executing stored procedures from the process
			table.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@cmd		nvarchar(4000)
,	@detail		varchar(4000)
,	@handler	varchar(255)
,	@parameters	varchar(65)
,	@type		char(3)
,	@result		int
,	@started	datetime

--	collect the handler and initialize the variables
select	@handler	=	isnull(@AlternateHandler, ProcessHandler)
	,	@parameters	=	case IncludeRunInfo
						when 1 then '  @RunId = '		+ cast(@runId as varchar)
								+	', @ProcessId = '	+ cast(@processId as varchar)
								+	', @ScheduleId = '	+ cast(@scheduleId as varchar)
						else '' end
	,	@detail		=	''
	,	@result		=	0
	,	@started	=	getdate()
from	tcu.Process
where	ProcessId = @processId;

exec tcu.Process_checkProcessType @handler, @type out;

if @type = 'PRC'
begin
	set	@cmd = 'exec @result = ' + @handler + @parameters;

	exec sp_executesql @cmd
					, N'@result int out'
					, @result out;
end;
else	-- didn't find the procedure
begin
	select	@result	= 1	--	failure
		,	@detail	= 'The specified stored procedure "' + @handler 
					+ '" does not exist in the database.';
end;

exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= @started
					,	@Result		= @result
					,	@Command	= @cmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO