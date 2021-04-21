use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_v]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/13/2006
Purpose  :	Combination of the HR Employee table and Active Directory view that 
			yeilds a full view of the Employee.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/24/2008	Paul Hunter		Added the EPMSCode to the view to determine managers.
03/03/2009	Paul Hunter		Added values from Active directory where the employee
							record isn't matched.
							Added the Company Name
————————————————————————————————————————————————————————————————————————————————
*/

select	coalesce(emp.EmployeeNumber
				, ad.EmployeeNumber, 0)	as EmployeeNumber
	,	coalesce(emp.PreferredName + ' ' + 
				 emp.LastName
				, ad.FullName, 'none')	as EmployeeName
	,	ad.samUserName					as PrincipalName
	,	coalesce(emp.LastName
				, ad.LastName, '')		as LastName
	,	coalesce(emp.FirstName
				, ad.FirstName, '')		as FirstName
	,	coalesce(emp.PreferredName
				, ad.FirstName, '')		as PreferredName
	,	emp.HiredOn
	,	coalesce(emp.Department
				, ad.Department, '')	as Department
	,	emp.DepartmentCode
	,	coalesce(emp.JobTitle
				, ad.Title, '')			as JobTitle
	,	lower(ad.Email)					as EmailAddress
	,	coalesce(emp.Telephone
				, ad.Phone, '')			as Telephone
	,	coalesce(emp.Ext
				, ad.Extension, '')		as Ext
	,	coalesce(emp.Fax
				, ad.Fax, '')			as Fax
	,	emp.Category
	,	emp.Type
	,	emp.Gender
	,	emp.Location
	,	emp.LocationCode
	,	coalesce(emp.Pager
				, ad.Pager, '')			as Pager
	,	coalesce(emp.Mobile
				, ad.Mobile, '')		as Mobile
	,	coalesce(emp.Address1
				, ad.Address1, '')		as Address1
	,	emp.Address2
	,	coalesce(emp.City
				, ad.City, '')			as City
	,	coalesce(emp.ZipCode
				, ad.PostalCode, '')	as ZipCode
	,	coalesce(emp.State
				, ad.State, '')			as State
	,	coalesce(emp.PersonId
				, ad.EmployeeId, 0)		as PersonId
	,	emp.Classification
	,	coalesce(mgr.PreferredName + ' ' + 
				 mgr.LastName
				, ad.Manager, '')		as ManagerName
	,	cast(coalesce(emp.PersonId
						, ad.EmployeeId, 0) as varchar)
						+ '.jpg'		as EmployeePhoto
 	,	case isnull(emp.EmployeeNumber, 0)
		when ad.EmployeeNumber then 'Both'
		when 0	then 'Active Directory'
		else 'HR File'
		end								as RecordSource
	,	coalesce(1 - cast(emp.IsDeleted as int)
				, ad.IsTerminated, 0)	IsActive
	,	emp.CostCenterCode
	,	emp.CostCenter
	,	mgr.CostCenterCode				as ManagerCostCenterCode
	,	mgr.CostCenter					as ManagerCostCenter
	,	case left(emp.EPMSCode, 3)
		when 'MGR' then 1
		when 'SLT' then 1
		else 0 end						as IsManager
	,	case emp.DepartmentCode
		when 'CULS00' then 'Credit Union Liquidity Services'
		when 'EDC000' then 'Texans Commercial Capital'
		when 'EDS000' then 'Strategic Shared Services'
		when 'TCM000' then 'Texans Financial'
		else 'Texans Credit Union'
		end								as Company
from	tcu.Employee	emp
left join
		tcu.Employee	mgr
		on	mgr.EmployeeNumber	= emp.ManagerNumber
		and	mgr.IsDeleted		= 0
full outer join
	(	select	samUserName
			,	FullName
			,	Email
			,	EmployeeNumber
			,	EmployeeId
			,	FirstName
			,	LastName
			,	Title
			,	Company
			,	Address1
			,	City
			,	State
			,	PostalCode
			,	Department
			,	Phone
			,	Extension
			,	Fax
			,	Pager
			,	Mobile
			,	Manager
			,	IsTerminated
		from	tcu.adUser_v
		where	EmployeeNumber		> 0
		and		IsTerminated		= 0	--	exclude terminated accounts
		and		IsServiceAccount	= 0	--	exclude service accounts
	)	ad	on	emp.EmployeeNumber	= ad.EmployeeNumber;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO