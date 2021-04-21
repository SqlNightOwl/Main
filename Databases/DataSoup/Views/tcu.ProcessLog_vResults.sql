use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessLog_vResults]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessLog_vResults]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessLog_vResults
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/05/2007
Purpose  :	Returns the results from the Process Log with a summary line for Runs
			that included multiple Processes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	l.ProcessLogId
	,	l.RunId
	,	l.ProcessId
	,	p.Process
	,	l.ScheduleId
	,	l.StartedOn
	,	l.FinishedOn
	,	l.Result
	,	RunTime		= cast(datediff(minute, l.StartedOn, l.FinishedOn) as varchar) + ':'
					+ tcu.fn_ZeroPad(datediff(second, l.StartedOn, l.FinishedOn) % 60, 2)
	,	l.Command
	,	l.Message
	,	RunOn		= cast(convert(char(10), l.StartedOn, 101) as datetime)
from	tcu.ProcessLog	l
join	tcu.Process		p
		on	l.ProcessId = p.ProcessId

union all

select	ProcessLogId	= (select max(ProcessLogId) + 1 from ProcessLog where RunId = m.RunId)
	,	RunId
	,	ProcessId		= null
	,	Process			= 'Total for Run ' + cast(RunId as varchar)
						+ ' (' + cast(Processes as varchar) + ' processes)'
	,	ScheduleId		= null
	,	StartedOn
	,	FinishedOn
	,	Results
	,	RunTime		= cast(datediff(minute, StartedOn, FinishedOn) as varchar) + ':'
					+ tcu.fn_ZeroPad(datediff(second, StartedOn, FinishedOn) % 60, 2)
	,	Command		= ''
	,	Message		= ''
	,	RunOn		= cast(convert(char(10), StartedOn, 101) as datetime)
from(	select	RunId
			,	StartedOn	= min(StartedOn)
			,	FinishedOn	= max(FinishedOn)
			,	Processes	= count(1)
			,	Results		= sum(Result)
		from	tcu.ProcessLog
		group by RunId having count(1) > 1
	)	m
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO