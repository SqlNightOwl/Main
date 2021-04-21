use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Employee_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[Employee_v]
GO
setuser N'risk'
GO
CREATE view risk.Employee_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/16/2009
Purpose  :	Retrieves employee's to which Devices and ScanDetail records may be
			Assigned.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	EmployeeNumber
	,	PreferredName + ' ' + LastName as Employee
	,	Department
	,	JobTitle
	,	IsDeleted
from	tcu.Employee
where	DepartmentCode in ('FRM000', 'ISH098', 'ISS098', 'ISS099', 'IST198');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO