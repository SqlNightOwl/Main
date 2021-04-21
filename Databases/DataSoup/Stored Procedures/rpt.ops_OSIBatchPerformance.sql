use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ops_OSIBatchPerformance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ops_OSIBatchPerformance]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ops_OSIBatchPerformance
	@EffDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/23/2008
Purpose  :	Returns start/finsih times, run time and number of applications per
			OSI queue between the effective date provided.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(2000);

exec ops.SSRSReportUsage_ins @@procid;

set	@EffDate = convert(char(10), isnull(@EffDate, getdate() - 1), 121);

set	@cmd = '
select	cast(''' + convert(char(10), @EffDate	, 101) + ''' as datetime)								as EffDate
	,	BatchStartDateTime
	,	BumpDateTime
	,	NtwkNodeName
	,	ProcessTypeId
	,	ProcessType
	,	QueNbr
	,	QueDesc
	,	cast(Applications as int)																		as Applications
	,	convert(char(8), StartDateTime, 8)																as StartTime
	,	convert(char(8), CompleteDateTime, 8)															as FinishTime
	,	case ProcessTypeId when 1 then datediff(minute, StartDateTime, CompleteDateTime) else 0 end		as DailyLength
	,	case ProcessTypeId when 2 then datediff(minute, StartDateTime, CompleteDateTime) else 0 end		as BatchLength
	,	case ProcessTypeId when 3 then datediff(minute, StartDateTime, CompleteDateTime) else 0 end		as ReportLength
	,	datediff(minute, StartDateTime, CompleteDateTime)												as RunLength
from	openquery(OSI, ''
select	NtwkNodeName
	,	ProcessTypeId
	,	ProcessType
	,	QueNbr
	,	QueDesc
	,	min(BatchStartDateTime)	as BatchStartDateTime
	,	min(BumpDateTime)		as BumpDateTime
	,	count(ApplNbr)			as Applications 
	,	min(StartDateTime)		as StartDateTime
	,	max(CompleteDateTime)	as CompleteDateTime
from	texans.ops_BatchProcess_vw
where	EffDate	= to_date(''''' + convert(char(10), @EffDate	, 101) + ''''', ''''mm/dd/yyyy'''')
group by NtwkNodeName, ProcessTypeId, QueNbr, QueDesc, ProcessType'')
order by NtwkNodeName, ProcessTypeId, StartDateTime;'

exec sp_executesql @cmd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO