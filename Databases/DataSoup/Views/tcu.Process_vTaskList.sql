use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_vTaskList]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Process_vTaskList]
GO
setuser N'tcu'
GO
CREATE view tcu.Process_vTaskList
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/19/2007
Purpose  :	Returns a list of Processes that should be produced at this time.
			NOTE:	This is the current Task List when the view is queried.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/18/2008	Paul Hunter		Changed the Frequency logic to be more consistent and
							easier to understand.
06/23/2008	Paul Hunter		Added ProcessCategory to the view.
————————————————————————————————————————————————————————————————————————————————
*/

select	p.ProcessId
	,	p.ScheduleId
	,	p.ProcessType
	,	p.ProcessCategory
	,	p.ChainId
	,	p.Sequence
	,	p.CancelChainOnError
	,	p.Process
	,	p.ProcessSchedule
from	tcu.Process_vTask	p
cross join	tcu.Today		t
where	p.IsEnabled			= 1	--	process is enabled...
		--	is scheduled at this time...
and		t.currentTime		between p.StartTime
								and p.EndTime
		--	its scheduled date is available...
and		t.currentDate		between p.BeginOn
								and p.EndOn
		--	and it hasn't been done for today...
and		t.currentDate		> p.LastRunOn
		--	this attempt is less than the total number of allowed attempts
and		p.AttemptsToday		<	p.Attempts
		--	and any holidays are skipped (if so requested)...
and		t.isCompanyHoliday	+ cast(p.SkipCompanyHolidays as int) < 2
and		t.isFederalHoliday	+ cast(p.SkipFederalHolidays as int) < 2
and		case
		--	specific types of days
		when (p.Frequency = 1)																			then 1	--	it run's continuously
		when((p.Frequency & 256)		= 256		and t.DayOfMonth = 1)								then 1	--	first day of the month
		when((p.Frequency & 512)		= 512		and t.DayOfMonth = t.lastDay)						then 1	--	last day of the month
		when((p.Frequency & 262144)		= 262144	and t.DayOfMonth = t.businessDayFirst)				then 1	--	first business day of the month
		when((p.Frequency & 524288)		= 524288	and t.DayOfMonth = t.businessDayLast)				then 1	--	last business day of the month
		--	a specific day and week of the month
		when((p.Frequency & 2048)		= 2048		and t.bitwiseDay = (p.Frequency & t.bitwiseDay))	then 1	--	first week of month
		when((p.Frequency & 4096)		= 4096		and t.bitwiseDay = (p.Frequency & t.bitwiseDay))	then 1	--	second week of month
		when((p.Frequency & 8192)		= 8192		and t.bitwiseDay = (p.Frequency & t.bitwiseDay))	then 1	--	third week of month
		when((p.Frequency & 16384)		= 16384		and t.bitwiseDay = (p.Frequency & t.bitwiseDay))	then 1	--	fourth week of month
		when((p.Frequency & 32768)		= 32768		and t.bitwiseDay = (p.Frequency & t.bitwiseDay))	then 1	--	last week of month
		--	a specific day
		when ((p.Frequency & t.bitwiseDay)	= t.bitwiseDay)												then 1	--	a specific day of the week
		else 0 end = 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO