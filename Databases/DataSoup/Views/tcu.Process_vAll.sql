use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_vAll]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Process_vAll]
GO
setuser N'tcu'
GO
CREATE view tcu.Process_vAll
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/31/2007
Purpose  :	Returns every attribute about a Process.  This returns a cartesian
			product as there will be multiple matches for each table.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	p.ProcessId
	,	p.Process
	,	p.ProcessType
	,	p.ProcessCategory
	,	p.ProcessHandler
	,	p.ProcessOwner
	,	p.[Description]						as ProcessDescription
	,	p.IncludeRunInfo
	,	p.SkipFederalHolidays
	,	p.SkipCompanyHolidays
	,	p.IsEnabled							as ProcessIsEnabled
	,	s.CashBox
	,	s.FundTypeCd
	,	s.FundTypeDetailCd
	,	s.TransactionCd
	,	s.TransactionDescription
	,	s.ClearingCategoryCd
	,	s.HasTraceNumber
	,	s.GLOffsetAccount
	,	s.GLOffsetTransactionCd
	,	s.GLOffsetDescription
	,	pf.FileName
	,	pf.TargetFile
	,	pf.AddDate
	,	pf.IsRequired
	,	pf.ApplName
	,	pp.Parameter
	,	pp.Value
	,	pp.ValueType
	,	pp.Description						as ParameterDescription
	,	ps.ScheduleId
	,	ps.ProcessSchedule
	,	convert(char(5), ps.StartTime, 108)	as StartTime
	,	convert(char(5), ps.EndTime, 108)	as EndTime
	,	ps.Frequency
	,	ps.Attempts
	,	ps.UsePriorDay
	,	ps.UseNewestFile
	,	convert(char(10), ps.BeginOn, 101)	as BeginOn
	,	convert(char(10), ps.EndOn, 101)	as EndOn
from	tcu.Process				p
left join
		tcu.ProcessSwim			s
		on	p.ProcessId	= s.ProcessId
left join
		tcu.ProcessFile			pf
		on	p.ProcessId	= pf.ProcessId
left join
		tcu.ProcessParameter	pp
		on	p.ProcessId	= pp.ProcessId
left join
		tcu.ProcessSchedule		ps
		on	p.ProcessId = ps.ProcessId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO