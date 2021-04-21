use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSchedule_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSchedule_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessSchedule_sav
	@ProcessId		smallint
,	@ScheduleId		tinyint			= null	output
,	@StartTime		varchar(8)
,	@EndTime		varchar(8)
,	@Frequency		int
,	@Attempts		tinyint
,	@IsEnabled		bit
,	@UsePriorDay	bit
,	@UseNewestFile	bit
,	@BeginOn		smalldatetime	= null
,	@EndOn			smalldatetime	= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	10/23/2007
Purpose  :	Inserts/Updates a record in the ProcessSchedule table based upon the
			primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/23/2008	Paul Hunter		Added logic to handle "On Demand" Processes.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@category	varchar(20)
,	@error		int
,	@method		varchar(6)
,	@proc		varchar(255)
,	@rows		int

set @method = 'update'
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	retrieve the category
select	@category	= ProcessCategory
from	tcu.Process
where	ProcessId	= @ProcessId

--	assign the next ScheduleId for the Process if one was not provided
set	@ScheduleId	= isnull(nullif(@ScheduleId, 0), tcu.fn_ProcessSchedule_NextId(@ProcessId))

--	make sure the start/end time contain only time
set	@StartTime	= nullif(rtrim(@StartTime), '')
if @StartTime is not null
	set	@StartTime	= convert(varchar(8), cast(@StartTime as datetime), 108)

set	@EndTime	= nullif(rtrim(@EndTime), '')
if @EndTime is not null
	set	@EndTime	= convert(varchar(8), cast(@EndTime as datetime), 108)

--	try doing an update first...
update	tcu.ProcessSchedule
set		ProcessSchedule	= ''
	,	StartTime		=	isnull(cast(@StartTime as datetime), StartTime)
	,	EndTime			=	isnull(cast(@EndTime as datetime), EndTime)
	,	Frequency		=	isnull(@Frequency, Frequency)
	,	Attempts		=	isnull(@Attempts, Attempts)
	,	IsEnabled		=	case @category
							when 'On Demand' then 1
							else isnull(@IsEnabled, IsEnabled) end
	,	UsePriorDay		=	isnull(@UsePriorDay, UsePriorDay)
	,	UseNewestFile	=	isnull(@UseNewestFile, UseNewestFile)
	,	BeginOn			=	isnull(@BeginOn, BeginOn)
	,	EndOn			=	isnull(@EndOn, EndOn)
	,	UpdatedBy		=	tcu.fn_UserAudit()
	,	UpdatedOn		=	getdate()
where	ProcessId		=	@ProcessId
and		ScheduleId		=	@ScheduleId

select	@error	= @@error
	,	@rows	= @@rowcount

--	if no rows were updated then try the insert.
if @rows = 0
begin
	set @method = 'insert'

	insert	tcu.ProcessSchedule
		(	ProcessId
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
		,	CreatedBy
		,	CreatedOn	)
	values
		(	@ProcessId
		,	nullif(rtrim(@ScheduleId), '')
		,	''	--	ProcessSchedule	is set by the trigger so any non-null value
		,	isnull(@StartTime		, '1900-01-01')
		,	isnull(@EndTime			, '1900-01-01')
		,	isnull(@Frequency		, 0)
		,	isnull(@Attempts		, 0)
		,	case @category
			when 'On Demand' then 1
			else isnull(@IsEnabled	, 0) end
		,	isnull(@UsePriorDay		, 0)
		,	isnull(@UseNewestFile	, 0)
		,	@BeginOn
		,	@EndOn
		,	tcu.fn_UserAudit()
		,	getdate()	)

	set	@error = @@error

end -- else (insert)

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc + '(' + @method + ')'
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
GRANT  EXECUTE  ON [tcu].[ProcessSchedule_sav]  TO [wa_Process]
GO