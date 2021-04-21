use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_department_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_department_get]
GO
setuser N'rpt'
GO
create procedure rpt.onyx_department_get
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/17/2009
Purpose  :	Retruns the Onyx Department list.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	0					as department_did
	,	'[All Departments]'	as department
	,	'Any'				as department_type

union all

select	department_did
	,	substring(department, 4, 50)	as department
	,	case left(department, 1)
		when 'B' then 'Branch'
		else 'Department' end			as department_type
from	Onyx6_0.cs.department_v
order by department_type, department;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO