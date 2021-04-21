use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_vTask]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Process_vTask]
GO
setuser N'tcu'
GO
CREATE view tcu.Process_vTask
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/08/2007
Purpose  :	Returns details of the Process, Chained Processes, Schedule and .
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/23/2008	Paul Hunter		Added ProcessCategory to the view.
03/27/2009	Paul Hunter		Removed the Schedule.IsEnabled check.  Changed to
							ANSI-92 syntax (as ColumnAlias)
————————————————————————————————————————————————————————————————————————————————
*/

select	isnull(c.ChainedProcessId	, p.ProcessId)					as ProcessId
	,	s.ScheduleId
	,	p.ProcessType
	,	p.ProcessCategory
	,	isnull(c.ScheduledProcessId	, p.ProcessId)					as ChainId
	,	isnull(c.Sequence			, 1)							as Sequence
	,	isnull(c.CancelChainOnError	, 0)							as CancelChainOnError
	,	p.Process
	,	p.SkipCompanyHolidays
	,	p.SkipFederalHolidays
	,	s.ProcessSchedule
	,	s.StartTime
	,	s.EndTime
	,	s.Frequency
	,	isnull(nullif(s.Attempts, 0), 255)							as Attempts
	,	isnull(s.BeginOn, t.currentDate)							as BeginOn
	,	isnull(s.EndOn	, t.currentDate)							as EndOn
	,	p.IsEnabled
	,	cast(isnull(case s.Frequency
					when 1 then 0
					else r.LastRunOn
					end, 0) as datetime)							as LastRunOn
	,	isnull(a.AttemptsToday, 0)									as AttemptsToday
	,	dateadd(day, -cast(s.UsePriorDay as int), t.currentDate)	as EffectiveOn
from	tcu.Process			p
cross join
		tcu.Today			t
left join
		tcu.ProcessChain	c
		on	p.ProcessId	= c.ChainedProcessId
join	tcu.ProcessSchedule	s
		on	s.ProcessId	= isnull(c.ScheduledProcessId, p.ProcessId)
left join
	(	--	collect successfully completed items from the log...
		select	ProcessId, ScheduleId
			,	LastRunOn = max(FinishedOn)
		from	tcu.ProcessLog
		where	Result = 0	--	success
		group by ProcessId, ScheduleId
	)	r	on	s.ProcessId		= r.ProcessId	
			and	s.ScheduleId	= r.ScheduleId
left join
	(	--	collect attempts for the current day...
		select	ProcessId, ScheduleId
			,	AttemptsToday	= count(1)
		from	tcu.ProcessLog
		where	FinishedOn	> convert(char(10), getdate(), 101)
		group by ProcessId, ScheduleId
	)	a	on	s.ProcessId 	= a.ProcessId
			and	s.ScheduleId	= a.ScheduleId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO