use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_getOrgChart]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_getOrgChart]
GO
setuser N'tcu'
GO
create procedure tcu.Employee_getOrgChart
	@ManagerNumber	int
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/11/2009
Purpose  :	Retrieves the organizational reports for the manager number provided.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

with cte_Hierarchy
	(	EmployeeId
	,	Employee
	,	Department
	,	DeptPath
	,	Title
	,	Extension
	,	Fax
	,	ManagerId
	,	Manager
	,	CostCenterCd
	,	CostCenter
	,	level
	)
as(	select	e.EmployeeNumber
		,	e.PreferredName + ' ' + e.LastName	as Employee
		,	e.Department
		,	cast('' as varchar(1000))			as DeptPath
		,	e.JobTitle
		,	e.Ext
		,	e.Fax
		,	e.ManagerNumber
		,	m.PreferredName + ' ' + m.LastName	as Employee
		,	e.CostCenterCode
		,	e.CostCenter
		,	cast(0 as int)						as level
	from	tcu.Employee	e
	left join
			tcu.Employee	m
			on	e.ManagerNumber = m.EmployeeNumber
			and	m.IsDeleted		= 0
	where	e.EmployeeNumber	= @ManagerNumber
	and		e.IsDeleted			= 0

	union all

	select	e.EmployeeNumber
		,	e.PreferredName + ' ' + e.LastName	as Employee
		,	e.Department
		,	cast(case h.DeptPath when '' then '' else h.DeptPath + '\' end + e.Department as varchar(1000))	as DeptPath
		,	e.JobTitle
		,	e.Ext
		,	e.Fax
		,	e.ManagerNumber
		,	m.PreferredName + ' ' + m.LastName		as Employee
		,	e.CostCenterCode
		,	e.CostCenter
		,	cast(h.level as int) + 1
	from	tcu.Employee	e
	join	cte_Hierarchy	h
			on	e.ManagerNumber = h.EmployeeId
	join	tcu.Employee	m
			on	e.ManagerNumber = m.EmployeeNumber
			and	e.IsDeleted		= m.IsDeleted
	where	e.IsDeleted = 0
)

select	*
from	cte_Hierarchy
order by DeptPath, level, Employee;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO