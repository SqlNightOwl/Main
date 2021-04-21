use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchProcessLog_getByDateOLD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[BatchProcessLog_getByDateOLD]
GO
setuser N'ops'
GO
CREATE procedure ops.BatchProcessLog_getByDate
	@FromDt datetime = null  
,	@ToDt	datetime = null  
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	02/03/2010
Purpose  :	Returns data in Hierarchial manner for the AspxTreeList Control.
History  :
  Date		Developer		Description
 
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare @now	datetime
set		@now = getdate()


select	@FromDt	= isnull(@FromDt, convert(char(10), (@now - 1)	, 101))
	,	@ToDt	= isnull(@ToDt	, convert(char(10), (@now)		, 101));

--	if From and To Dates are greater than Bump Date then exit out
if	(@ToDt		< @FromDt)	or
	(@FromDt	> tcu.fn_OSIPostDate() and
	 @ToDt		> tcu.fn_OSIPostDate())
return;


exec ops.BatchProcessTables_sav;


create table #Hier
(	UId				int					identity	
,	ParentId		int					not null
,	NodeDesc		varchar(60)			not null
,	ServerName		varchar(100)			null
,	QueNbr			int						null
,	ApplNbr			int						null
,	SeqNbr			int						null
,	ApplName		varchar(100)			null
,	StartTime		datetime				null
,	StopTime		datetime				null
,	ExecTime		float					null
,	CompleteStatus	int						null
,	StdDev			int						null
,	Median			int						null
) 


--********************************************
--insert Top most Hierarchy element (ie. EffDate) as ParentID = 0
insert	#Hier
	(	ParentId
	,	NodeDesc
	)
select	distinct	
		0 as ParentId
	,	convert(char(10), EffDate, 101 ) as NodeDesc
from	ops.BatchProcessLog	
where	EffDate	between @FromDt	and	@ToDt 
order by NodeDesc desc

--********************************************
--insert next hierarchy elements ie. Template level
insert	#Hier
	(	ParentId
	,	NodeDesc
	,	ServerName
	,	QueNbr
	,	StartTime
	,	StopTime
	,	ExecTime
	,	CompleteStatus
	,	StdDev
	,	Median
	)
select	z.UID					as ParentId
	,	t.BatchTemplate			as NodeDesc
	,	min(l.NtwkNodeName)		as ServerName
	,	l.QueNbr
	,	min(l.ApplStartTime)	as	StartTime
	,	max(isnull(l.ApplStopTime, cast('01/01/2050' as datetime)))  as  StopTime
/*
	 '01/01/2050' is specified for cases when a template is in progress. 
	 Otherwise it was picking max(l.ApplStopTime) and considering that status is complete for template which is not true.
	 We mark nulls as '01/01/2050' and later upddate it back to null
*/
	,	case
		--	Appl execution hasn't started
		when	(min(l.ApplStartTime)	is null)
		 and	(max(l.ApplStopTime)	is null)	then	null
		--	Appl is in execution phase
		when	(min(l.ApplStartTime)				is	not null)
		and		(max(isnull(l.ApplStopTime, @now))	=	@now)	then	datediff(second, min(l.ApplStartTime), @now)
		--	Appl has completed execution
		else	sum(l.ApplExecTime)
		end	as	ExecTime
	,	case
		--	Appl execution hasn't started
		when	(min(l.ApplStartTime)	is null)
		 and	(max(l.ApplStopTime)	is null)	then 0
		--	Appl is in execution phase
		when	(min(l.ApplStartTime)	is	not null)
		 and	(max(l.ApplStopTime)	is	null)	then 1
		--	Appl has completed execution
		else	2
		end as	CompleteStatus
	,	sum(l.StdDev) as StdDev  
	,	sum(l.Median) as Median
from	#Hier					z

join	ops.BatchProcessLog		l
		on	z.NodeDesc = l.EffDate
join	ops.BatchTemplate		t
		on	l.BatchTemplateId = t.BatchTemplateId
group by
		z.UID
	,	l.QueNbr
	,	t.BatchTemplate


update	#Hier
set		StopTime		= null
	,	CompleteStatus	= 1
where	StopTime		= '01/01/2050'

--********************************************
--insert next hierarchy element ie. Appl level (which are leaf nodes)
insert	#Hier
select	z.UID			as ParentId
	,	a.ApplDesc		as NodeDesc
	,	l.NtwkNodeName	as ServerName
	,	l.QueNbr
	,	l.ApplNbr
	,	l.SeqNbr
	,	a.ApplName
	,	l.ApplStartTime as StartTime
	,	l.ApplStopTime  as StopTime
	,	case
		--	Appl execution hasn't started
		when	(l.ApplStartTime	is null)
		 and	(l.ApplStopTime		is null)	then	null
		--	Appl is in execution phase
		when	(l.ApplStartTime	is not null) 
		 and	(l.ApplStopTime		is null)	then	datediff(ss, l.ApplStartTime, @now)
		--	Appl has completed execution
 		else	l.ApplExecTime
		end as	ExecTime
	,	case
		--	Appl execution hasn't started
		when	(l.ApplStartTime	is null)
		 and	(l.ApplStopTime		is null)	then	0
		--	Appl is in execution phase
		when	(l.ApplStartTime	is not null)
		 and	(l.ApplStopTime		is null)	then	1
		--	Appl has completed execution
		else	2	
		end as	CompleteStatus
	,	a.StdDev
	,	a.Median
from	#Hier							z
join	ops.BatchProcessLog				l
		on	z.QueNbr = l.QueNbr
join	ops.BatchTemplateApplication	a
		on	l.BatchTemplateId = a.BatchTemplateId
		and	l.ApplNbr = a.ApplNbr
		and	l.QueSubNbr = a.QueSubNbr
--where	InActiveOn is null	@ToDt
order by	l.QueNbr
		,	l.SeqNbr

--********************************************
-- Display the data as needed with other calculated columns
select	* 
	,	case 
			when	ExecTime	>		Median + StdDev		then 'Red'
			when	ExecTime	>		Median				then 'Yellow'
			when	ExecTime	>		0					then 'Green'
			when	CompleteStatus =	0					then 'Grey'
			else	''
		end as		ExecStatus
	,	case	
			when	(median/60) = 0					then '<1'
			else	cast((median/60) as varchar) 
		end as		MedianExecTime   
	,	case	
			when	Round(ExecTime/60,0) = 0		then '<1'
			else	cast(Round(ExecTime/60,0) as varchar) 
		end as		ActualExecTime  

	,	case	
			when	CompleteStatus = 2		then 100
			when	CompleteStatus = 1		then ExecTime /(Median + (2*StdDev)) * 100 
			else	0
		end as		ProgressBar
from	#Hier 
order by
		ServerName
	,	CompleteStatus
	,	StartTime	desc
	,	QueNbr		desc
	,	SeqNbr

drop table	#Hier;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO