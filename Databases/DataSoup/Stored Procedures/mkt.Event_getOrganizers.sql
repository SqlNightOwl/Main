use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_getOrganizers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_getOrganizers]
GO
setuser N'mkt'
GO
create procedure mkt.Event_getOrganizers
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/11/2006
Purpose  :	Retrieves unique Organizers for the various Events
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	Organizer	= ltrim(rtrim(Organizer))
from	mkt.Event
where	rtrim(isnull(Organizer, '')) != ''
group by ltrim(rtrim(Organizer))
order by ltrim(rtrim(Organizer))
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_getOrganizers]  TO [wa_Marketing]
GO