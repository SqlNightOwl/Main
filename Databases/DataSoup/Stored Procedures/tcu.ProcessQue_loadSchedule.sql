use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessQue_loadSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessQue_loadSchedule]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessQue_loadSchedule
	@ProcessId	smallint	= null
,	@ScheduleId	tinyint		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/13/2010
Purpose  :	Loads the ProcessQue with the scheduled or "requested" Processes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@MAX_WARN	int
,	@result		int
,	@runId		int
,	@runOn		char(19)
,	@user		varchar(25)

--	get the next available Run Id...
exec @runId = tcu.Process_getNextRunId;

--	iniitalize the parameters/variables...
select	@ProcessId	= isnull(@ProcessId		, 0)
	,	@ScheduleId	= isnull(@ScheduleId	, 0)
	,	@MAX_WARN	= 15	--	maximum number of warnings recorded before the process can be rescheduled
	,	@result		= 0
	,	@runId		= isnull(nullif(@runId	, 0), 1)	--	make sure thereiss a run id
	,	@runOn		= convert(char(16), getdate(), 120) + ':00'
	,	@user		= tcu.fn_UserAudit();

--	if the Process Id and Schedule Id are provided then it's a manual run...
if(	@ProcessId	> 0	and
	@ScheduleId	> 0	)
begin
	/*
	**	QUE THE MANUAL REQUEST
	*/
	--	a specific process and schedule was provided...
	insert	tcu.ProcessQue
		(	IsManualRun
		,	RunId
		,	ProcessId
		,	ScheduleId
		,	Process
		,	ProcessType
		,	Category
		,	RunOn
		,	ScheduledBy
		)
	select	distinct
			1
		,	@runId
		,	t.ProcessId
		,	t.ScheduleId
		,	t.Process
		,	t.ProcessType
		,	t.ProcessCategory
		,	cast(@runOn as datetime)
		,	@user
	from	tcu.Process_vTask	t
	left join	--	exclude tasks that are already scheduled
			tcu.ProcessQue		q
			on	t.ProcessId	 = q.ProcessId
			and	t.ScheduleId = q.ScheduleId
	where	t.ProcessId		= @ProcessId
	and		t.ScheduleId	= @ScheduleId
	and	(	q.ProcessId		is null
		or	q.Warnings		> @MAX_WARN );

	set	@result = @@error;
end;
else
begin
	/*
	**	QUE THE REGULAR/NORMAL REQUEST
	*/
	--	the next sheduled processes...
	insert	tcu.ProcessQue
		(	IsManualRun
		,	RunId
		,	ProcessId
		,	ScheduleId
		,	Process
		,	ProcessType
		,	Category
		,	RunOn
		,	ScheduledBy
		)
	select	distinct
			0
		,	@runId
		,	t.ProcessId
		,	t.ScheduleId
		,	t.Process
		,	t.ProcessType
		,	t.ProcessCategory
		,	cast(@runOn as datetime)
		,	@user
	from	tcu.Process_vTaskList	t
	left join	--	exclude tasks that are already scheduled
			tcu.ProcessQue			q
			on	t.ProcessId	 = q.ProcessId
			and	t.ScheduleId = q.ScheduleId
	where(	q.ProcessId	is null
		or	q.Warnings	> @MAX_WARN )
	order by
			t.ProcessId
		,	t.ScheduleId;

	set	@result = @@error;

	--	set the dictionary last run time...
	exec tcu.Dictionary_sav 'Process', 'Last Run Time', @runOn

end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO