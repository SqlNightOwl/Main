use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[PlayList_del]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[PlayList_del]
GO
setuser N'mkt'
GO
create procedure mkt.PlayList_del
	@PlayListId	tinyint
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	01/24/2008
Purpose  :	Deletes a record from the mktPlayList and mktFlashPlayList table based
			upon the primary key.  Also reassigns the default playlist id to the
			affected locations.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/25/2008	Paul Hunter		Added check to make sure the default Play Lists are
							not deleted.  Changed the order of events to take
							into consideration the foriegn key on the Locations
							(must reassign before the Play List can be deleted).
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	cannot delete a default play list (0 and 1)
if @PlayListId < 2
begin
	raiserror('You cannot delete a default Play List!', 15, 1) with log
	return @@error
end

--	remove the files from the playlist
delete	mkt.FlashFilePlayList
where	PlayListId	= @PlayListId

--	update the affected locations
update	tcu.Location
set		PlayListId	=	case LocationType
						when 'Drive Thru' then 1	--	this is the default drive thru play list id
						else 0 end					--	this is the standard "default" play list id
where	PlayListId	=	@PlayListId

--	now it's save to delete the PlayList
delete	mkt.PlayList
where	PlayListId	= @PlayListId

set	@error = @@error

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @errmsg) with log
end

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[PlayList_del]  TO [wa_Marketing]
GO