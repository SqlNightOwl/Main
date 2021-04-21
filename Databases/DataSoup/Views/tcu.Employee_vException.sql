use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vException]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vException]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_vException
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/28/2008
Purpose  :	Used to produce the exceptions file after the new HR file is loaded.
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	'Found In'			as FoundIn
	,	'Employee Name'		as EmployeeName
	,	'Principal Name'	as PrincipalName
	,	'Employee Number'	as EmployeeNumber
	,	'Person Id'			as PersonId

union all

select	RecordSource
	,	EmployeeName
	,	PrincipalName
	,	cast(EmployeeNumber as varchar)
	,	cast(PersonId as varchar)
from	tcu.Employee_v
where	RecordSource	!=	'both'
and	(	IsActive		=	1
	or	IsActive		is null);
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO