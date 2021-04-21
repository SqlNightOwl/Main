use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_getEventTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_getEventTypes]
GO
setuser N'mkt'
GO
create procedure mkt.Event_getEventTypes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developee:	Paul Hunter
Created  :	05/11/2006
Purpose  :	Retrieves unique EventTypes for the various Events
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	distinct
		EventType
from	mkt.Event
group by EventType
order by EventType
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_getEventTypes]  TO [wa_Marketing]
GO