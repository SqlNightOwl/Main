use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vTemplate]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vTemplate]
GO
setuser N'tcu'
GO
create view tcu.Employee_vTemplate
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/28/2008
Purpose  :	Used as a template for building the load table for the HR data file.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/24/2008	Paul Hunter		Added the new EPMS Code column to the template.
————————————————————————————————————————————————————————————————————————————————
*/

select	top 0
		LastName
	,	FirstName
	,	PreferredName
	,	cast(null as int)	as EmployeeNumber
	,	HiredOn
	,	Department
	,	CostCenterCode
	,	CostCenter
	,	DepartmentCode
	,	JobTitle
	,	Telephone
	,	Ext
	,	Fax
	,	Category
	,	Classification
	,	Type
	,	Pager
	,	Gender
	,	Mobile
	,	Location
	,	LocationCode
	,	Address1
	,	Address2
	,	City
	,	ZipCode
	,	PersonId
	,	ManagerNumber
	,	EPMSCode
from	tcu.Employee;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO