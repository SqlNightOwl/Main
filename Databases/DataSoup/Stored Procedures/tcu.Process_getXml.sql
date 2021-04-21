use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_getXml]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_getXml]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_getXml
	@ProcessId	smallint	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/30/2007
Purpose  :	Returns the Process details as an XML document fragment.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/08/2008	Fijula Kuniyil	Added Notification Types detail for UI display only.
01/14/2008	Fijula Kuniyil	Added Swim node to xml
09/24/2008	Fijula Kuniyil	Added null handling for process owner field.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@STATUS	char(5)

set	@STATUS = 'clean';

select	tag		= 1
	,	parent	= null
	,	null		as [Processes!1!!element]
	--	Process
	,	null		as [Process!2!id]
	,	null		as [Process!2!name]
	,	null		as [Process!2!type]
	,	null		as [Process!2!category]
	,	null		as [Process!2!handler]
	,	null		as [Process!2!owner]
	,	null		as [Process!2!includeRunInfo]
	,	null		as [Process!2!skipFederalHoliday]
	,	null		as [Process!2!skipCompanyHoliday]
	,	null		as [Process!2!isEnabled]
	,	null		as [Process!2!lastProcessedOn]
	,	null		as [Process!2!description]
	,	null		as [Process!2!status]
	--	Schedules
	,	null		as [Schedule!3!scheduleId]
	,	null		as [Schedule!3!startTime]
	,	null		as [Schedule!3!endTime]
	,	null		as [Schedule!3!frequency]
	,	null		as [Schedule!3!attempts]
	,	null		as [Schedule!3!isEnabled]
	,	null		as [Schedule!3!usePriorDay]
	,	null		as [Schedule!3!useNewestFile]
	,	null		as [Schedule!3!beginOn]
	,	null		as [Schedule!3!endOn]
	,	null		as [Schedule!3!description]	--	this value is "calculated"
	,	null		as [Schedule!3!status]
	--	Files
	,	null		as [File!4!ownerId]
	,	null		as [File!4!fileName]
	,	null		as [File!4!targetFile]
	,	null		as [File!4!addDate]
	,	null		as [File!4!isRequired]
	,	null		as [File!4!applName]
	,	null		as [File!4!lastRunOn]
	,	null		as [File!4!status]
	--	Parameters
	,	null		as [Parameter!5!ownerId]
	,	null		as [Parameter!5!name]
	,	null		as [Parameter!5!value]
	,	null		as [Parameter!5!type]
	,	null		as [Parameter!5!description]
	,	null		as [Parameter!5!status]
	--	Notification
	,	null		as [Notification!6!ownerId]
	,	null		as [Notification!6!types]
	,	null		as [Notification!6!recipient]
	,	null 		as [Notification!6!typesdetail]
	,	null		as [Notification!6!status]
	--	Chains
	,	null		as [Chain!7!schedulerId]
	,	null		as [Chain!7!scheduler]
	,	null		as [Chain!7!chainedId]
	,	null		as [Chain!7!chained]
	,	null		as [Chain!7!sequence]
	,	null		as [Chain!7!cancelOnError]
	,	null		as [Chain!7!position]
	,	null		as [Chain!7!status]
	--	Swim
	,	null 		as [Swim!8!ownerId]
	, 	null 		as [Swim!8!CashBox]
	, 	null 		as [Swim!8!FundTypeCode]
	, 	null		as [Swim!8!FundTypeDetailCode]
	, 	null		as [Swim!8!TransactionCode]
	,	null		as [Swim!8!TransactionDescription]
	,	null		as [Swim!8!ClearingCategoryCode]
	,	null		as [Swim!8!HasTraceNumber]
	,	null		as [Swim!8!GLOffsetAccount]
	,	null		as [Swim!8!GLOffsetTransactionCode]
	,	null		as [Swim!8!GLOffsetDescription]

union all

select	tag		= 2
	,	parent	= 1
	,	null
	--	Processes
	,	p.ProcessId
	,	p.Process
	,	p.ProcessType
	,	p.ProcessCategory
	,	isnull(p.ProcessHandler, '')
	,	isnull(p.ProcessOwner, '')
	,	p.IncludeRunInfo
	,	p.SkipFederalHolidays
	,	p.SkipCompanyHolidays
	,	p.IsEnabled
	,	isnull(convert(varchar(10), pl.MaxLastRun, 101), '')
	,	p.Description
	,	@STATUS
	--	Schedules
	,	0		--	scheduleId
	,	null	--	startTime
	,	null	--	endTime
	,	null	--	frequency
	,	null	--	attempts
	,	null	--	isEnabled
	,	null	--	usePriorDay
	,	null	--	useNewestFile
	,	null	--	beginOn
	,	null	--	endOn
	,	null	--	description is "calculated"
	,	null	--	status
	--	Files
	,	p.ProcessId	--	ownerId
	,	null	--	fileName
	,	null	--	targetFile
	,	null	--	addDate
	,	null	--	isRequired
	,	null	--	applName
	,	null	--	lastRunOn
	,	null	--	status
	--	Parameters
	,	p.ProcessId	--	ownerId
	,	null	--	name
	,	null	--	value
	,	null	--	type
	,	null	--	description
	,	null	--	status
	--	Notification
	,	p.ProcessId	--	ownerId
	,	null	--	types
	,	null	--	recipient
	,	null 	-- 	typesdetail
	,	null	--	status
	--	Chain
	,	null	--	schedulerId
	,	null	--	scheduler
	,	null	--	chainedId
	,	null	--	chained
	,	null	--	sequence
	,	null	--	cancelOnError
	,	null	--	position
	,	null	--	status
--	Swim
	,	p.ProcessId 	--	ownerId
	, 	null 	--	CashBox
	, 	null 	--	FundTypeCd
	, 	null	--	FundTypeDetailCd
	, 	null	--	TransactionCd
	,	null	--	TransactionDescription
	,	null	--	ClearingCategoryCd
	,	null	--	HasTraceNumber
	,	null	--	GLOffsetAccount
	,	null	--	GLOffsetTransactionCd
	,	null	--	GLOffsetDescription
from	tcu.Process	p
left join
	(	select	ProcessId, MaxLastRun = max(FinishedOn)
		from	tcu.ProcessLog
		where	ProcessId	= isnull(@ProcessId, ProcessId)
		and		Result		= 0
		group by ProcessId
	)	pl	on	p.ProcessId = pl.ProcessId
where	p.ProcessId	= isnull(@ProcessId, p.ProcessId)

union all

select	tag		= 3
	,	parent	= 2
	,	null
	--	Processes
	,	ProcessId
	,	null	--	Process
	,	null	--	Type
	,	null	--	Category
	,	null	--	Handler
	,	null	--	Owner
	,	null	--	IncludeRunInfo
	,	null	--	SkipFederalHolidays
	,	null	--	SkipCompanyHolidays
	,	null	--	IsEnabled
	,	null	--	LastRunOn
	,	null	--	Description
	,	null	--	status
	--	Schedules
	,	ScheduleId
	,	convert(char(5), StartTime, 8)
	,	convert(char(5), EndTime, 8)
	,	Frequency
	,	Attempts
	,	IsEnabled
	,	UsePriorDay
	,	UseNewestFile
	,	isnull(convert(varchar(10), EndOn, 101), '')
	,	isnull(convert(varchar(10), EndOn, 101), '')
	,	ProcessSchedule
	,	@STATUS	--	status
	--	Files
	,	ProcessId	--	ownerId
	,	null	--	fileName
	,	null	--	targetFile
	,	null	--	addDate
	,	null	--	isRequired
	,	null	--	applNumber
	,	null	--	lastRunOn
	,	null	--	status
	--	Parameters
	,	ProcessId	--	ownerId
	,	null	--	parameter
	,	null	--	value
	,	null	--	valueType
	,	null	--	description
	,	null	--	status
	--	Notificaion
	,	ProcessId	--	ownerId
	,	null	--	type
	,	null	--	recipient
	,	null 	-- 	typesdetail
	,	null	--	status
	--	Chain
	,	null	--	schedulerId
	,	null	--	scheduler
	,	null	--	chainedId
	,	null	--	chained
	,	null	--	sequence
	,	null	--	cancelOnError
	,	null	--	position
	,	null	--	status
--	Swim
	,	ProcessId 	--	ownerId
	, 	null 	--	CashBox
	, 	null 	--	FundTypeCd
	, 	null	--	FundTypeDetailCd
	, 	null	--	TransactionCd
	,	null	--	TransactionDescription
	,	null	--	ClearingCategoryCd
	,	null	--	HasTraceNumber
	,	null	--	GLOffsetAccount
	,	null	--	GLOffsetTransactionCd
	,	null	--	GLOffsetDescription
from	tcu.ProcessSchedule
where	ProcessId	= isnull(@ProcessId, ProcessId)

union all

select	tag		= 4
	,	parent	= 2
	,	null
	--	Process
	,	pf.ProcessId
	,	null	--	Process
	,	null	--	Type
	,	null	--	Category
	,	null	--	Handler
	,	null	--	Owner
	,	null	--	IncludeRunInfo
	,	null	--	SkipFederalHolidays
	,	null	--	SkipCompanyHolidays
	,	null	--	IsEnabled
	,	null	--	LastRunOn
	,	null	--	Description
	,	null	--	status
	--	Files
	,	1004	--	ScheduleId
	,	null	--	StartTime
	,	null	--	EndTime
	,	null	--	Frequency
	,	null	--	Attempts
	,	null	--	IsEnabled
	,	null	--	UsePriorDay
	,	null	--	UseNewestFile
	,	null	--	BeginOn
	,	null	--	EndOn
	,	null	--	ProcessSchedule
	,	null	--	status
	--	Files
	,	pf.ProcessId
	,	pf.FileName
	,	isnull(pf.TargetFile, '')
	,	pf.AddDate
	,	pf.IsRequired
	,	isnull(pf.applName, '')
	,	isnull(convert(varchar(10), pl.MaxLastRun, 101), '')
	,	@STATUS	--	status
	--	Parameters
	,	pf.ProcessId	--	ownerId
	,	null	--	parameter
	,	null	--	value
	,	null	--	vValueType
	,	null	--	description
	,	null	--	status
	--	Notificaion
	,	pf.ProcessId	--	ownerId
	,	null	--	Type
	,	null	--	Recipient
	,	null 	-- 	typesdetail
	,	null	--	status
	--	Chain
	,	null	--	schedulerId
	,	null	--	scheduler
	,	null	--	chainedId
	,	null	--	chained
	,	null	--	sequence
	,	null	--	cancelOnError
	,	null	--	position
	,	null	--	status
--	Swim
	,	pf.ProcessId 	--	ownerId
	, 	null 	--	CashBox
	, 	null 	--	FundTypeCd
	, 	null	--	FundTypeDetailCd
	, 	null	--	TransactionCd
	,	null	--	TransactionDescription
	,	null	--	ClearingCategoryCd
	,	null	--	HasTraceNumber
	,	null	--	GLOffsetAccount
	,	null	--	GLOffsetTransactionCd
	,	null	--	GLOffsetDescription
from	tcu.ProcessFile	pf
left join
	(	select	ProcessId, MaxLastRun = max(FinishedOn)
		from	tcu.ProcessLog
		where	ProcessId	= isnull(@ProcessId, ProcessId) and Result = 0
		group by ProcessId
	)	pl	on	pf.ProcessId = pl.ProcessId
where	pf.ProcessId	= isnull(@ProcessId, pf.ProcessId)

union all

select	tag		= 5
	,	parent	= 2
	,	null
	--	Process
	,	ProcessId
	,	null	--	Process
	,	null	--	Type
	,	null	--	Category
	,	null	--	Handler
	,	null	--	Owner
	,	null	--	IncludeRunInfo
	,	null	--	SkipFederalHolidays
	,	null	--	SkipCompanyHolidays
	,	null	--	IsEnabled
	,	null	--	LastRunOn
	,	null	--	Description
	,	null	--	status
	--	Files
	,	1005	--	ScheduleId
	,	null	--	StartTime
	,	null	--	EndTime
	,	null	--	Frequency
	,	null	--	Attempts
	,	null	--	IsEnabled
	,	null	--	UsePriorDay
	,	null	--	UseNewestFile
	,	null	--	BeginOn
	,	null	--	EndOn
	,	null	--	ProcessSchedule
	,	null	--	status
	--	Files
	,	ProcessId	--	ownerId
	,	'zz'	--	FileName
	,	null	--	TargetFile
	,	null	--	AddDate
	,	null	--	IsRequired
	,	null	--	applName
	,	null	--	LastProcessedOn
	,	null	--	status
	--	Parameters
	,	ProcessId
	,	Parameter
	,	Value
	,	ValueType
	,	Description
	,	@STATUS	--	status
	--	Notificaion
	,	ProcessId
	,	0		--	Type
	,	null	--	Recipient
	,	null 	-- 	typesdetail
	,	null	--	status
	--	Chain
	,	null	--	schedulerId
	,	null	--	scheduler
	,	null	--	chainedId
	,	null	--	chained
	,	null	--	sequence
	,	null	--	cancelOnError
	,	null	--	position
	,	null	--	status
--	Swim
	,	ProcessId 	--	ownerId
	, 	null 	--	CashBox
	, 	null 	--	FundTypeCd
	, 	null	--	FundTypeDetailCd
	, 	null	--	TransactionCd
	,	null	--	TransactionDescription
	,	null	--	ClearingCategoryCd
	,	null	--	HasTraceNumber
	,	null	--	GLOffsetAccount
	,	null	--	GLOffsetTransactionCd
	,	null	--	GLOffsetDescription
from	tcu.ProcessParameter
where	ProcessId	= isnull(@ProcessId, ProcessId)

union all

select	tag		= 6
	,	parent	= 2
	,	null
	--	Process
	,	ProcessId
	,	null	--	Process
	,	null	--	Type
	,	null	--	Category
	,	null	--	Handler
	,	null	--	Owner
	,	null	--	IncludeRunInfo
	,	null	--	SkipFederalHolidays
	,	null	--	SkipCompanyHolidays
	,	null	--	IsEnabled
	,	null	--	LastRunOn
	,	null	--	Description
	,	null	--	status
	--	Files
	,	1006	--	ScheduleId
	,	null	--	StartTime
	,	null	--	EndTime
	,	null	--	Frequency
	,	null	--	Attempts
	,	null	--	IsEnabled
	,	null	--	UsePriorDay
	,	null	--	UseNewestFile
	,	null	--	BeginOn
	,	null	--	EndOn
	,	null	--	ProcessSchedule
	,	null	--	status
	--	Files
	,	ProcessId	--	ownerId
	,	'zz'	--	FileName
	,	null	--	TargetFile
	,	null	--	AddDate
	,	null	--	IsRequired
	,	null	--	applName
	,	null	--	LastProcessedOn
	,	null	--	status
	--	Parameters
	,	ProcessId	--	ownerId
	,	'zz'	--	Parameter
	,	null	--	Value
	,	null	--	ValueType
	,	null	--	Description
	,	null	--	status
	--	Notificaion
	,	ProcessId
	,	MessageTypes
	,	Recipient
	,	TypesDetail	= tcu.fn_ProcessNotificationTypes(MessageTypes)
	,	@STATUS	--	status
	--	Chain
	,	null	--	schedulerId
	,	null	--	scheduler
	,	null	--	chainedId
	,	null	--	chained
	,	null	--	sequence
	,	null	--	cancelOnError
	,	null	--	position
	,	null	--	status
--	Swim
	,	ProcessId 	--	ownerId
	, 	null 	--	CashBox
	, 	null 	--	FundTypeCd
	, 	null	--	FundTypeDetailCd
	, 	null	--	TransactionCd
	,	null	--	TransactionDescription
	,	null	--	ClearingCategoryCd
	,	null	--	HasTraceNumber
	,	null	--	GLOffsetAccount
	,	null	--	GLOffsetTransactionCd
	,	null	--	GLOffsetDescription
from	tcu.ProcessNotification
where	ProcessId	= isnull(@ProcessId, ProcessId)

union all

select	tag		= 7
	,	parent	= 2
	,	null
	--	Process
	,	coalesce(sp.ProcessId, cp.ProcessId, @ProcessId)
	,	null	--	Process
	,	null	--	Type
	,	null	--	Category
	,	null	--	Handler
	,	null	--	Owner
	,	null	--	IncludeRunInfo
	,	null	--	SkipFederalHolidays
	,	null	--	SkipCompanyHolidays
	,	null	--	IsEnabled
	,	null	--	LastRunOn
	,	null	--	Description
	,	null	--	status
	--	Files
	,	1007	--	ScheduleId
	,	null	--	StartTime
	,	null	--	EndTime
	,	null	--	Frequency
	,	null	--	Attempts
	,	null	--	IsEnabled
	,	null	--	UsePriorDay
	,	null	--	UseNewestFile
	,	null	--	BeginOn
	,	null	--	EndOn
	,	null	--	ProcessSchedule
	,	null	--	status
	--	Files
	,	coalesce(sp.ProcessId, cp.ProcessId, @ProcessId)	--	ownerId
	,	'zz'	--	FileName
	,	null	--	TargetFile
	,	null	--	AddDate
	,	null	--	IsRequired
	,	null	--	applName
	,	null	--	LastProcessedOn
	,	null	--	status
	--	Parameters
	,	coalesce(sp.ProcessId, cp.ProcessId, @ProcessId)	--	ownerId
	,	'zz'	--	Parameter
	,	null	--	Value
	,	null	--	ValueType
	,	null	--	Description
	,	null	--	status
	--	Notificaion
	,	coalesce(sp.ProcessId, cp.ProcessId, @ProcessId)
	,	1007	--	Type
	,	null	--	Recipient
	,	null
	,	null	--	status
	--	Chains
	,	pc.ScheduledProcessId
	,	ScheduledProcess	=	sp.Process
	,	pc.ChainedProcessId
	,	ChainedProcess		=	cp.Process
	,	pc.Sequence
	,	pc.CancelChainOnError
	,	Position			=	case pc.ScheduledProcessId
								when pc.ChainedProcessId then 'Scheduler'
								else 'Worker' end
	,	@STATUS	--	status
--	Swim
	,	coalesce(sp.ProcessId, cp.ProcessId, @ProcessId) 	--	ownerId
	, 	null 	--	CashBox
	, 	null 	--	FundTypeCd
	, 	null	--	FundTypeDetailCd
	, 	null	--	TransactionCd
	,	null	--	TransactionDescription
	,	null	--	ClearingCategoryCd
	,	null	--	HasTraceNumber
	,	null	--	GLOffsetAccount
	,	null	--	GLOffsetTransactionCd
	,	null	--	GLOffsetDescription
from	tcu.ProcessChain	pc
join	tcu.Process			sp
		on	pc.ScheduledProcessId	= sp.ProcessId
join	tcu.Process			cp
		on	pc.ChainedProcessId		= cp.ProcessId
where(	pc.ScheduledProcessId	= @ProcessId
	or	pc.ChainedProcessId		= @ProcessId	)

union all

select	tag		= 8
	,	parent	= 2
	,	null
	--	Process
	,	ProcessId
	,	null	--	Process
	,	null	--	Type
	,	null	--	Category
	,	null	--	Handler
	,	null	--	Owner
	,	null	--	IncludeRunInfo
	,	null	--	SkipFederalHolidays
	,	null	--	SkipCompanyHolidays
	,	null	--	IsEnabled
	,	null	--	LastRunOn
	,	null	--	Description
	,	null	--	status
	--	Files
	,	1007	--	ScheduleId
	,	null	--	StartTime
	,	null	--	EndTime
	,	null	--	Frequency
	,	null	--	Attempts
	,	null	--	IsEnabled
	,	null	--	UsePriorDay
	,	null	--	UseNewestFile
	,	null	--	BeginOn
	,	null	--	EndOn
	,	null	--	ProcessSchedule
	,	null	--	status
	--	Files
	,	ProcessId	--	ownerId
	,	'zz'	--	FileName
	,	null	--	TargetFile
	,	null	--	AddDate
	,	null	--	IsRequired
	,	null	--	applName
	,	null	--	LastProcessedOn
	,	null	--	status
	--	Parameters
	,	ProcessId	--	ownerId
	,	'zz'	--	Parameter
	,	null	--	Value
	,	null	--	ValueType
	,	null	--	Description
	,	null	--	status
	--	Notificaion
	,	ProcessId
	,	1007	--	Type
	,	null	--	Recipient
	,	null
	,	null	--	status
		--	Chain
	,	null	--	schedulerId
	,	null	--	scheduler
	,	null	--	chainedId
	,	null	--	chained
	,	null	--	sequence
	,	null	--	cancelOnError
	,	null	--	position
	,	null	--	status
--	Swim
	,	ProcessId 	--	ownerId
	, 	CashBox
	, 	FundTypeCd
	, 	FundTypeDetailCd
	, 	TransactionCd
	,	TransactionDescription
	,	ClearingCategoryCd
	,	HasTraceNumber
	,	GLOffsetAccount
	,	GLOffsetTransactionCd
	,	GLOffsetDescription
from	tcu.ProcessSwim
where	ProcessId	= isnull(@ProcessId, ProcessId)

--	the order by clause is critical as it controls how the XML nodes get linked together
order by
		[Process!2!id]
	,	[Schedule!3!scheduleId]
	,	[File!4!ownerId]
	,	[File!4!fileName]
	,	[Parameter!5!ownerId]
	,	[Parameter!5!name]
	,	[Notification!6!ownerId]
	,	[Notification!6!recipient]
	,	[Chain!7!schedulerId]
	,	[Chain!7!sequence]
for xml explicit;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Process_getXml]  TO [wa_Process]
GO