use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[MessageType_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[MessageType_get]
GO
setuser N'tcu'
GO
create procedure tcu.MessageType_get
	@MessageType	tinyint		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/19/2008
Purpose  :	Returns a specific Message Type or a list of available Message Types.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	MessageType
	,	MessageTypeName
	,	Description
	,	BitValue
from	tcu.MessageType
where	@MessageType = MessageType
	or	@MessageType is null
order by
		MessageType

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO