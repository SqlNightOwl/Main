use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessType_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessType_get]
GO
setuser N'tcu'
GO
create procedure tcu.ProcessType_get
	@ProcessType	char(3)		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/19/2008
Purpose  :	Returns a specific Process Type or a list of available Process Types.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	ProcessType
	,	Description
from	tcu.ProcessType
where	@ProcessType = ProcessType
	or	@ProcessType is null
order by
		ProcessType

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[ProcessType_get]  TO [wa_Process]
GO