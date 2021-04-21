use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessCategory]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessCategory]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessCategory
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/14/2008
Purpose  :	List of valid Process Categories.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	ProcessCategory = left(ReferenceValue, 20)
	,	Description
from	tcu.ReferenceValue
where	ReferenceId	in ( select	ReferenceId from tcu.Reference
						 where	ReferenceObject	= 'Process.ProcessCategory'	)
and		IsEnabled	= 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO