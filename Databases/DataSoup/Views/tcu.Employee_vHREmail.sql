use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vHREmail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vHREmail]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_vHREmail
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/28/2008
Purpose  :	Used to produce the HR Email file after the new HR file is loaded.
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/03/2009	Paul Hunter		Changed to ANSI SQL92 query.
————————————————————————————————————————————————————————————————————————————————
*/

select	'Person Id'	as PersonId
	,	'Email'		as Email

union all

select	cast(PersonId as varchar(10))
	,	Email
from	tcu.Employee
where	isDeleted	= 0
and		Email		is not null;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO