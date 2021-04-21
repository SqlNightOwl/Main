use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ops_ProcessStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ops_ProcessStatus]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ops_ProcessStatus
	@RunOn		datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/23/2008
Purpose  :	Returns a list of the scheduled processes for the specified date and
			the execution status for the Processes.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/10/2008	Paul Hunter		Added ProcessChain so that chained Processes are
							included in the results.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set	@RunOn = convert(char(10), isnull(@RunOn, getdate()), 121) ;

select	RunId		= isnull(l.RunId, 0)
	,	l.ProcessLogId
	,	p.ProcessId
	,	s.ScheduleId
	,	ProcessType	= p.ProcessCategory
	,	p.Process
	,	s.ProcessSchedule
	,	StartAt		= convert(char(8), isnull(cast(l.StartedOn as datetime), s.StartTime), 8)
	,	FinishAt	= convert(char(8), l.FinishedOn, 8)
	,	l.RunTime
	,	RunLength	= isnull(datediff(second, l.StartedOn, l.FinishedOn), 0)
	,	Result		= m.MessageTypeName
	,	l.Message
	,	Processes	= isnull(c.Processes, 0)
from(	select * from tcu.fn_DateDetails(@RunOn) )	t
	,	tcu.Process					p
left join
		tcu.ProcessChain			x
		on	p.ProcessId = x.ChainedProcessId
join	tcu.ProcessSchedule			s
		on	s.ProcessId	= isnull(x.ScheduledProcessId, p.ProcessId)
left join	tcu.ProcessLog_vResults	l
		on	l.ProcessId		= isnull(x.ChainedProcessId, p.ProcessId)
		and	l.ScheduleId	= s.ScheduleId
		and	@RunOn			= convert(char(10), isnull(cast(l.StartedOn as datetime), @RunOn), 121)
left join	tcu.MessageType			m
		on	l.Result		= m.MessageType
left join
	(	--	count the number of processes per run excluding continuously running processes that succeed
		select	l.RunId, Processes = count(distinct l.ProcessId)
		from	tcu.ProcessLog l join tcu.ProcessSchedule s
				on l.ProcessId = s.ProcessId
		where	convert(char(10), l.StartedOn, 121) = @RunOn
		and		case s.Frequency when 1 then isnull(l.Result, 1) else 1 end > 0
		group by l.RunId
	)	c	on	l.RunId = c.RunId
where(	p.IsEnabled			= 1	or				--	the process is enabled   -- OR--
		(p.ProcessCategory	= 'On Demand' and	--	it's on demand 
		 l.RunId			> 0					--	and was executed
		)
	 )
		--	it ran for the effective date
and		t.effectiveDate		between isnull(s.BeginOn, t.effectiveDate)
							and		isnull(s.EndOn	, t.effectiveDate)
		--	and any holidays are skipped (if so requested)...
and		t.isCompanyHoliday	+ cast(p.SkipCompanyHolidays as int) < 2
and		t.isFederalHoliday	+ cast(p.SkipFederalHolidays as int) < 2
		--	exclude continuously running processes unless they don't succeed!
and		case s.Frequency
		when 1 then	case
					when p.ProcessCategory = 'On Demand' then 1
					else isnull(l.Result, 1) end
		else s.Frequency end > 0
and		case
		--	specific types of days
		when (s.Frequency = 1)																			then 1	--	it run's continuously
		when((s.Frequency & 256)		= 256		and 1 = t.DayOfMonth)								then 1	--	first day of the month
		when((s.Frequency & 512)		= 512		and 1 = t.isLastDayOfMonth)							then 1	--	last day of the month
		when((s.Frequency & 262144)		= 262144	and t.DayOfMonth = t.businessDayFirst)				then 1	--	first business day of the month
		when((s.Frequency & 524288)		= 524288	and t.DayOfMonth = t.businessDayLast)				then 1	--	last business day of the month
		--	a specific day and week of the month
		when((s.Frequency & 2048)		= 2048		and t.bitwiseDay = (s.Frequency & t.bitwiseDay))	then 1	--	first week of month
		when((s.Frequency & 4096)		= 4096		and t.bitwiseDay = (s.Frequency & t.bitwiseDay))	then 1	--	second week of month
		when((s.Frequency & 8192)		= 8192		and t.bitwiseDay = (s.Frequency & t.bitwiseDay))	then 1	--	third week of month
		when((s.Frequency & 16384)		= 16384		and t.bitwiseDay = (s.Frequency & t.bitwiseDay))	then 1	--	fourth week of month
		when((s.Frequency & 32768)		= 32768		and t.bitwiseDay = (s.Frequency & t.bitwiseDay))	then 1	--	last week of month
		--	a specific day
		when ((s.Frequency & t.bitwiseDay)	= t.bitwiseDay)												then 1	--	a specific day of the week
		else 0 end = 1

order by
		l.RunId
	,	l.ProcessLogId
	,	l.StartedOn;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO