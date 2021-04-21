use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_getProcessCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_getProcessCategories]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_getProcessCategories
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/29/2007
Purpose  :	Returns a list of available Process Categories.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	ProcessCategory
	,	Description
from	tcu.ProcessCategory
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO