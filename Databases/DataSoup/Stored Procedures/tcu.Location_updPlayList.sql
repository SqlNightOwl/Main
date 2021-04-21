use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_updPlayList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Location_updPlayList]
GO
setuser N'tcu'
GO
create procedure tcu.Location_updPlayList
	@PlayListId		tinyint
,	@LocationList	varchar(4000)
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	11/06/2005
Purpose  :	Updates the Play List Id for the list of Locations in the @Locations
			variable.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
01/25/2008	Paul Hunter		Changed data type on @PlayListId parameter and the
							length on the @LocationList parameter.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int

set	@error	= 0

update	l
set		PlayListId	= @PlayListId
from	tcu.Location						l
join	tcu.fn_split(@LocationList, ',')	ll
		on	l.LocationId = cast(ll.Value as int)
where	isnumeric(ll.Value) = 1

set	@error = @@error

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Location_updPlayList]  TO [wa_Marketing]
GO