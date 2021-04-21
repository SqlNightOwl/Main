use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[osi_BranchTraffic]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[osi_BranchTraffic]
GO
setuser N'rpt'
GO
CREATE procedure rpt.osi_BranchTraffic
	@MonthOf	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/21/2008
Purpose  :	Retruns summarized Branch Traffic data for the specified month.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@endOn		datetime
,	@startOn	datetime;

exec ops.SSRSReportUsage_ins @@procid;

set	@startOn	= tcu.fn_FirstDayOfMonth(isnull(@MonthOf, dateadd(month, -1, getdate())));
set	@endOn		= tcu.fn_LastDayOfMonth(@startOn);

select	b.OrgName			as Branch
	,	c.RtxnTypCatDesc	as Category
	,	rpt.MinItems
	,	rpt.MaxItems
	,	rpt.AverageItems
	,	rpt.TotalItems
	,	rpt.MinAmount
	,	rpt.MaxAmount
	,	rpt.AverageAmount
	,	rpt.TotalAmount
from(	select	BranchNbr
			,	CategoryCd
			,	min(Items)	as MinItems
			,	max(Items)	as MaxItems
			,	avg(Items)	as AverageItems
			,	sum(Items)	as TotalItems
			,	min(Amount)	as MinAmount
			,	max(Amount)	as MaxAmount
			,	avg(Amount)	as AverageAmount
			,	sum(Amount)	as TotalAmount
		from	osi.BranchTraffic	bt
		where	PostedOn between @startOn and @endOn
		group by BranchNbr, CategoryCd
	)	rpt
join	openquery(OSI, '
		select	OrgNbr, OrgName
		from	texans.Branch_vw'
	)	b	on	rpt.BranchNbr	= b.OrgNbr
join	openquery(OSI, '
		select	RtxnTypCatCd, RtxnTypCatDesc
		from	osiBank.RtxnTypCat'
	)	c	on	rpt.CategoryCd	= c.RtxnTypCatCd
order by
		b.OrgName
	,	c.RtxnTypCatDesc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [rpt].[osi_BranchTraffic]  TO [TEXANSCU\saSqlRpt]
GO