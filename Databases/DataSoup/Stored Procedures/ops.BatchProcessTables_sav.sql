use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchProcessTables_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[BatchProcessTables_sav]
GO
setuser N'ops'
GO
CREATE procedure ops.BatchProcessTables_sav
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	01/22/2010
Purpose  :	1)	Finds new Templates from OSI and inserts into ops.BatchTemplate table.
			2)	Adds new  Template applications into ops.BatchTemplateApplication table.
			3)	Also adds Parameters for new Appls.
			4)	Calculates Stats just for new templates-applications.
			5)	Updates existing Que in BatchProcessLog table from OSI.
				Also adds new Que information.
History  :
  Date		Developer		Description
 ——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare	@maxBatchTemplateId int

create table #temp
	(	CreatedByQueNbr	int				not null
	,	NtwkNodeName	varchar(100)	null
	,	ApplNbr			int				not null
	,	QueSubNbr		smallint		not null
	,	SeqNbr			smallint		not	null
	,	QueNbr			int				not null
	,	EffDate			datetime		null
	,	SchedDateTime	datetime		null
	,	ApplStartTime	datetime		null
	,   ApplStopTime   	datetime		null
	,	ApplExecTime	int				null
	,   ReturnCd		int				null
	,	RowId			int identity	primary key
	);
create unique index ak_temp		on #temp (CreatedByQueNbr, QueNbr, ApplNbr, QueSubNbr);
create index ix_QueApplQueSub	on #temp (QueNbr, ApplNbr, QueSubNbr);

insert	#temp
select	*
from	openquery(OSI,'
		select	CreatedByQueNbr
			,	NtwkNodeName
			,	ApplNbr
			,	QueSubNbr
			,	SeqNbr
			,	QueNbr
			,	EffDate
			,	SchedDateTime
 			,	ApplStartTime
			,   ApplStopTime
			,	ApplExecTime
			,   ReturnCd
		from	ops_BatchProcessLog_vw');

--	update existing Que in BatchProcessLog
update	l
set		ApplStopTime	= t.ApplStopTime
	,	ApplStartTime	= t.ApplStartTime
	,	ApplExecTime	= isnull(nullif(t.ApplExecTime, 0), 1)
	,	ReturnCd		= t.ReturnCd
from	ops.BatchProcessLog		l
join	#temp					t
		on	l.QueNbr	= t.QueNbr
		and	l.ApplNbr	= t.ApplNbr
		and	l.QueSubNbr	= t.QueSubNbr;

--	get max BatchProcessLogId
select	@maxBatchTemplateId = max(BatchProcessLogId)
from	ops.BatchProcessLog;

--	add any new templates...
insert	ops.BatchTemplate
select  o.QueNbr
	,	o.QueDesc
	,	o.QueTypCd
	,	o.DateLastMaint
from(	select	CreatedByQueNbr
		from	#temp				n
		left join
				ops.BatchTemplate	t
				on	n.CreatedByQueNbr = t.BatchTemplateId
		where	t.BatchTemplateId	is null
		group by CreatedByQueNbr )	n
join	openquery(OSI,'
		select	QueNbr
			,	QueDesc
			,	QueTypCd
			,	DateLastMaint
		from	Que
		where	DateLastMaint > trunc(sysdate) - 1') o
		on	o.QueNbr = n.CreatedByQueNbr;

--	add new template appls...And template appl parameters
--	get new templates appls into temp table
select	t.CreatedByQueNbr
	,	t.ApplNbr
	,	t.QueSubNbr
into	#newAppl
from	#temp							t
left join
		ops.BatchTemplateApplication	ta
		on	ta.BatchTemplateId	= t.CreatedByQueNbr
		and ta.ApplNbr			= t.ApplNbr
		and ta.QueSubNbr		= t.QueSubNbr
where	ta.BatchTemplateId is null
group by
		t.CreatedByQueNbr
	,	t.ApplNbr
	,	t.QueSubNbr;

if exists (	select top 1 * from  #newAppl )
begin
	insert	ops.BatchTemplateApplication
	select	a.QueNbr	as BatchTemplateId
		,	a.ApplNbr
		,	a.QueSubNbr
		,	a.SeqNbr
		,	a.ApplName
		,	a.ApplDesc
		,	-1			as StdDev
		,	0			as Median
		,	a.DateLastMaint
	from	#newAppl				n
	join	openquery(OSI,'
			select  qa.QueNbr
				,	qa.ApplNbr
				,   qa.QueSubNbr
				,	qa.SeqNbr
				,	a.ApplName
				,	a.ApplDesc
				,   qa.DateLastMaint
			from	Que		q
			join	QueAppl	qa
					on	q.QueNbr = qa.QueNbr
			join	Appl	a
					on	qa.ApplNbr = a.ApplNbr
			where	qa.DateLastMaint > trunc(sysdate) - 1
			order by	qa.QueNbr
					,	qa.SeqNbr')		a
			on	n.CreatedByQueNbr	= a.QueNbr
			and	n.ApplNbr			= a.ApplNbr
			and n.QueSubNbr			= a.QueSubNbr;

	insert	ops.BatchTemplateParameters
	select	a.QueNbr as	BatchTemplateId
		,	a.ApplNbr
		,	a.QueSubNbr
		,	a.ParameterCd
		,	a.ParameterValue
		,	a.DateLastMaint
	from	#newAppl		n
	join	openquery(OSI,'
			select	p.QueNbr
				,	p.ApplNbr
				,	p.QueSubNbr
				,	p.ParameterCd
				,	p.ParameterValue
				,	p.DateLastMaint
			from	Que				q
			join	QueApplParam	p
					on	q.QueNbr = p.QueNbr
			where p.DateLastMaint > trunc(sysdate) - 1
			order by	q.QueNbr
					,	p.ApplNbr
					,	p.QueSubNbr')	a
			on	a.QueNbr	=	n.CreatedByQueNbr
			and	a.ApplNbr	=	n.ApplNbr
			and	a.QueSubNbr =	n.QueSubNbr;
end;

drop table #newAppl;

--	add new log records...
insert	ops.BatchProcessLog
select	t.CreatedByQueNbr	as BatchTemplateId
	,	t.NtwkNodeName
	,	t.ApplNbr
	,	t.QueSubNbr
	,	t.SeqNbr
	,	t.QueNbr
	,	t.EffDate
	,	t.SchedDateTime
	,	t.ApplStartTime
	,   t.ApplStopTime
	,	isnull(nullif(t.ApplExecTime, 0), 1) as ApplExecTime
	,   t.ReturnCd
	,	-1				as StdDev
	,	0				as Median
from	#temp				t
left join
		ops.BatchProcessLog	l
		on	l.QueNbr	= t.QueNbr
		and	l.ApplNbr	= t.ApplNbr
		and	l.QueSubNbr	= t.QueSubNbr
where	l.QueNbr	is null
	and	l.ApplNbr	is null
	and	l.QueSubNbr is null;


--	calc stats. for newly added Template Appls (Update StandardDeviation values in ops.BatchTemplateApplication)
update	a
set		StdDev	= b.StdDeviation
	,	Median	= b.Median
from	ops.BatchTemplateApplication	a
join(	select	l.BatchTemplateId
			,	l.ApplNbr
			,	l.QueSubNbr
			,	coalesce(stdev(cast(l.ApplExecTime as int)), 60)	as StdDeviation
			,	coalesce(avg(cast(l.ApplExecTime as int)), 60)		as Median
		from	ops.BatchTemplateApplication	ta
		join	ops.BatchProcessLog				l
				on	ta.BatchTemplateId	= l.BatchTemplateId
				and ta.ApplNbr			= l.ApplNbr
				and ta.QueSubNbr		= l.QueSubNbr
		where	BatchProcessLogId	> @maxBatchTemplateId
		and		ta.StdDev			= -1
		group by
				l.BatchTemplateId
			,	l.ApplNbr
			,	l.QueSubNbr	)	b
		on	a.BatchTemplateId	= b.BatchTemplateId
		and	a.ApplNbr			= b.ApplNbr
		and	a.QueSubNbr			= b.QueSubNbr;

--	update Median and Std Dev in BatchProcessLog for new Que
update	l
set		Median	=	ta.Median
	,	StdDev	=	ta.StdDev
from	ops.BatchTemplateApplication	ta
join	ops.BatchProcessLog				l
		on	ta.BatchTemplateId	= l.BatchTemplateId
		and ta.ApplNbr			= l.ApplNbr
		and ta.QueSubNbr		= l.QueSubNbr
where	l.BatchProcessLogId > @maxBatchTemplateId;

drop table #temp;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO