use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[CostCenter_vHierarchy]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[CostCenter_vHierarchy]
GO
setuser N'tcu'
GO
CREATE view tcu.CostCenter_vHierarchy
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/01/2009
Purpose  :	Returns a list of Cost Centers ordered by.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

with	cte_CostCenter
	(	CostCenter
	,	CenterLevel
	,	CostCenterSort
	)
as 
(
	select	CostCenter
		,	0 as CenterLevel
		,	cast(CostCenterName as varchar(1000)) as CostCenterSort
	from	tcu.CostCenter
	where	ParentCostCenter is null

	union all

	select	c.CostCenter
		,	CenterLevel + 1
		,	cast(p.CostCenterSort + '|' + c.CostCenterName as varchar(1000))
	from	tcu.CostCenter	c
	join	cte_CostCenter	p
			on	c.ParentCostCenter = p.CostCenter
)

select	top 1000
		row_number() over (order by h.CostCenterSort) as RecordId
	,	c.CostCenter
	,	c.CostCenterName
	,	c.ManagerNumber
	,	c.IsFinancial
	,	c.IsActive
	,	h.CostCenterSort
	,	h.CenterLevel
from	cte_CostCenter	h
join	tcu.CostCenter	c
		on h.CostCenter = c.CostCenter
order by h.CostCenterSort;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO