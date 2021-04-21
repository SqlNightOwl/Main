use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[lnd_DepartmentList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[lnd_DepartmentList]
GO
setuser N'rpt'
GO
CREATE procedure rpt.lnd_DepartmentList
	@DepartmentList		varchar(4000)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/18/2005
Purpose  :	Retrieves a list of Departments from the Enterprise database for the
			specified CSV list of Department ID's or all departments if the list
			@DepartmentList is null
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

exec ops.SSRSReportUsage_ins @@procid

set	@DepartmentList = nullif(rtrim(@DepartmentList), '')

select	DepartmentID	= null
	,	Department		= '<All Departments>'
where	@DepartmentList is null

union all

select	DepartmentID
	,	Department		= DeptName
from	Legacy.ep.Department
where	(DepartmentID	in (select	cast(Value as int)
							from	tcu.fn_split(@DepartmentList, ',')
							where	isnumeric(Value) = 1))
or		(@DepartmentList is null)
order by
		Department
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO