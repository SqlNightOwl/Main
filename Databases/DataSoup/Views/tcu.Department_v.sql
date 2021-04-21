use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Department_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Department_v]
GO
setuser N'tcu'
GO
create view tcu.Department_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/14/2008
Purpose  :	Returns a unique list of non-null active Departments from the 
			tcu.Employee table.  This data is generated from the HR file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	DepartmentCode
	,	Department	= min(Department)
from	tcu.Employee
where	DepartmentCode	is not null
and		IsDeleted		= 0
group by DepartmentCode;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO