use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[NotificationTag_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[NotificationTag_get]
GO
setuser N'mkt'
GO
create procedure mkt.NotificationTag_get
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/02/2008
Purpose  :	Retrieves the replacable notification tags for use in sending the
			event responses.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	NotificationTag	= v.ReferenceValue
	,	v.Description
from	tcu.ReferenceValue	v
join	tcu.Reference		r
		on	v.ReferenceId = r.ReferenceId
where	r.ReferenceObject = 'EventResponse.NotificationTags'
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[NotificationTag_get]  TO [wa_Marketing]
GO