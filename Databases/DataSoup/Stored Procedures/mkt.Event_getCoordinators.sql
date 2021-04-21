use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_getCoordinators]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_getCoordinators]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Event_getCoordinators
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil	
Created  :	06/17/2008
Purpose  :	Retrieves unique Coordinators for the various Events
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	distinct Coordinator
from	mkt.Event
where	Coordinator	is not null
order by Coordinator
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_getCoordinators]  TO [wa_Marketing]
GO