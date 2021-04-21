use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSchedule_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSchedule_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessSchedule_get
	@ProcessId		smallint		= null
,	@ScheduleId		tinyint			= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	10/29/2007
Purpose  :	Retrieves record(s) from the ProcessSchedule table based upon the
			primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

select	ProcessId
	,	ScheduleId
	,	ProcessSchedule
	,	StartTime
	,	EndTime
	,	Frequency
	,	Attempts
	,	IsEnabled
	,	UsePriorDay
	,	UseNewestFile
	,	BeginOn
	,	EndOn
from	tcu.ProcessSchedule
where	ProcessId	= isnull(@ProcessId	, ProcessId )
and		ScheduleId	= isnull(@ScheduleId, ScheduleId )

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
GRANT  EXECUTE  ON [tcu].[ProcessSchedule_get]  TO [wa_Process]
GO