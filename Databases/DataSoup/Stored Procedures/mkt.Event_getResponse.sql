use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_getResponse]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_getResponse]
GO
setuser N'mkt'
GO
Create procedure mkt.Event_getResponse
	@EventId	int
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil	
Created  :	07/02/2008
Purpose  :	Retrieves Messages to be sent as event registration response.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	EventId
	,	MessageType
	,	Subject
	,	Body
from	mkt.EventResponse
where	EventId	= @EventId
order by MessageType
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_getResponse]  TO [wa_Marketing]
GO