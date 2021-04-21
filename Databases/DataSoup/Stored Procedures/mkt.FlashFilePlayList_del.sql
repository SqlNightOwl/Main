use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFilePlayList_del]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[FlashFilePlayList_del]
GO
setuser N'mkt'
GO
create procedure mkt.FlashFilePlayList_del
	@PlayListId		tinyint
,	@Sequence		tinyint
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	09/11/2006
Purpose  :	Deletes a record from the mktFlashFilePlayList table based upon the
			primary key.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
01/25/2008	Paul Hunter		Renamed procedure to fit new schema
01/31/2008	Fijula Kuniyil	Rearranged the sequence numbers to avoid the break after delete.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	delete the file from the list
delete 	mkt.FlashFilePlayList
where	PlayListId 	= @PlayListId
and		Sequence	= @Sequence

--	resequence the remaining files in the list
update	mkt.FlashFilePlayList
set		Sequence	=	Sequence - 1
where	Sequence	>=	@Sequence
and		PlayListId	=	@PlayListId

set	@error = @@error

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[FlashFilePlayList_del]  TO [wa_Marketing]
GO