use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessCategory_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessCategory_get]
GO
setuser N'tcu'
GO
create procedure tcu.ProcessCategory_get
	@ProcessCategory	varchar(20)		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/19/2008
Purpose  :	Returns a specific Process Category or a list of available Process
			Categories.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	ProcessCategory
	,	Description
from	tcu.ProcessCategory
where	@ProcessCategory = ProcessCategory
	or	@ProcessCategory is null
order by
		ProcessCategory

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[ProcessCategory_get]  TO [wa_Process]
GO