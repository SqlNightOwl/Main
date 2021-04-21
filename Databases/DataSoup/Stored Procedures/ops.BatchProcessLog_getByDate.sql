use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchProcessLog_getByDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[BatchProcessLog_getByDate]
GO
setuser N'ops'
GO
CREATE procedure [ops].[BatchProcessLog_getByDate]
	@FromDt	datetime	= null
,	@ToDt	datetime	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	02/03/2010
Purpose  :	Returns data in Hierarchial manner for the AspxTreeList control.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@bumpDate		datetime
,	@IN_PROGRESS	datetime
,	@now			datetime
,	@return			int

select	@bumpDate		= tcu.fn_OSIPostDate()
	,	@IN_PROGRESS	= '01/01/2100'
	,	@now			= getdate()
	,	@return			= 0
	,	@FromDt			= convert(char(10), isnull(@FromDt, getdate() - 1)	, 121)
	,	@ToDt			= convert(char(10), isnull(@ToDt  , getdate())		, 121);

create table #hierarchy
	(	UId				int identity	primary key
	,	ParentId		int				not null
	,	NodeDesc		varchar(60)		not null
	,	ServerName		varchar(100)	null
	,	QueNbr			int				null
	,	ApplNbr			int				null
	,	SeqNbr			smallint		null
	,	ApplName		varchar(100)	null
	,	StartTime		datetime		null
	,	StopTime		datetime		null
	,	ExecTime		int				null
	,	CompleteStatus	int				null
	,	StdDev			int				null
	,	Median			int				null
	,	EffDate			datetime		not null
	);

--	retrieve a copy of the the BatchTemplateLog table
select	*
into	#log
from	ops.BatchProcessLog
where	EffDate	between @FromDt
					and	@ToDt
order by BatchProcessLogId;

--	if From and To Dates are greater than Bump Date then exit out
if	@ToDt	< @FromDt
or(	@FromDt	> @bumpDate	and
	 @ToDt	> @bumpDate	)
	set	@return = -1
else
begin
	--	update the table only if you're not looking at history
	if	@FromDt >= (@bumpDate - 1)
		exec ops.BatchProcessTables_sav;

	--	insert top most Hierarchy element (ie. EffDate) as ParentId = 0
	insert	#hierarchy
		(	ParentId
		,	NodeDesc
		,	EffDate
		)
	select	0
		,	convert(char(10), EffDate, 101)
		,	EffDate
	from	#log
	group by EffDate
	order by EffDate desc;

	--	insert next hierarchy elements ie. Template level
	insert	#hierarchy
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
		,	EffDate
		)
	select	ParentId
		,	NodeDesc
		,	ServerName
		,	QueNbr
		,	StartTime
		,	isnull(StopTime, @IN_PROGRESS)	as StopTime
			/*
			**	@IN_PROGRESS is specified for cases when a template is in progress
			**	Otherwise the max StopTime gets used an it and treats the template status as complete which is incorrect
			**	We mark nulls as '01/01/2050' and later upddate it back to null
			*/
		,	case cast(isnull(StartTime, 0) as int)
			when 0 then null	--	not started
			--	running or completed
			else isnull(nullif(datediff(second, StartTime, isnull(StopTime, @now)), 0), 1)
			end			as ExecTime
		,	case
			--	not started
			when StartTime	is null		then 0
			--	running
			when StartTime	is not null
			 and StopTime	is null		then 1
			--	completed
			else 2
			end			as CompleteStatus
		,	StdDev
		,	Median
		,	EffDate
	from(	select	h.UID					as ParentId
				,	t.BatchTemplate			as NodeDesc
				,	l.QueNbr
				,	l.EffDate
				,	min(l.NtwkNodeName)		as ServerName
				,	min(l.ApplStartTime)	as StartTime
				,	max(l.ApplStopTime)		as StopTime
				,	sum(l.StdDev)			as StdDev
				,	sum(l.Median)			as Median
			from	#hierarchy			h
			join	#log				l
					on	h.EffDate = l.EffDate
			join	ops.BatchTemplate	t
					on	l.BatchTemplateId = t.BatchTemplateId
			group by
					h.UID
				,	l.EffDate
				,	l.QueNbr
				,	t.BatchTemplate	) s;

	update	#hierarchy
	set		StopTime		= null
		,	CompleteStatus	= 1
	where	StopTime		= @IN_PROGRESS;

	--	insert next hierarchy element ie. Appl level (which are leaf nodes)
	insert	#hierarchy
	select	z.UID			as ParentId
		,	a.ApplDesc		as NodeDesc
		,	l.NtwkNodeName	as ServerName
		,	l.QueNbr
		,	l.ApplNbr
		,	l.SeqNbr
		,	a.ApplName
		,	l.ApplStartTime	as StartTime
		,	l.ApplStopTime	as StopTime
		,	case cast(isnull(l.ApplStartTime, 0) as int)
			when 0	then null	--	not started
			--	running or completed
			else isnull(nullif(datediff(second, l.ApplStartTime, isnull(l.ApplStopTime, @now)), 0), 1)
			end				as ExecTime
		,	case
			--	not started
			when l.ApplStartTime	is null		then 0
			--	running
			when l.ApplStartTime	is not null
			 and l.ApplStopTime		is null		then 1
			--	completed
			else 2
			end			as CompleteStatus
		,	a.StdDev
		,	a.Median
		,	l.EffDate
	from	#hierarchy						z
	join	#log							l
			on	z.QueNbr = l.QueNbr
	join	ops.BatchTemplateApplication	a
			on	l.BatchTemplateId	= a.BatchTemplateId
			and	l.ApplNbr			= a.ApplNbr
			and	l.QueSubNbr			= a.QueSubNbr
	order by	l.QueNbr
			,	l.SeqNbr;
end;

--	display the data as needed with other calculated columns
select	*
	,	case
		when CompleteStatus = 0					then 'Grey'
		when ExecTime		> Median + StdDev	then 'Red'
		when ExecTime		> Median			then 'Yellow'
		when ExecTime		> 0					then 'Green'
		else ''
		end		as ExecStatus
	,	case (median / 60)
		when 0 then '<1'
		else cast((median / 60) as varchar(10))
		end		as MedianExecTime
	,	case round(ExecTime / 60, 0)
		when 0 then '<1'
		else cast(round(ExecTime / 60, 0) as varchar(10))
		end		as ActualExecTime
	,	case CompleteStatus
		when 1 then ExecTime /(Median + (2 * StdDev)) * 100
		when 2		then 100
		else 0
		end		as ProgressBar
from	#hierarchy
order by
		ServerName
	,	CompleteStatus
	,	EffDate		desc
	,	StartTime	desc
	,	QueNbr		desc
	,	SeqNbr

drop table #hierarchy;
drop table #log;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO