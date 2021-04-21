use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[PlayList_getFlashFiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[PlayList_getFlashFiles]
GO
setuser N'mkt'
GO
CREATE procedure mkt.PlayList_getFlashFiles
	@PlayListId		tinyint			= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/01/2006
Purpose  :	Retrieves record(s) from the mktPlayList and any related mktFlashFile
			files based upon the PlayListId.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/26/2007	Paul Hunter		Added the EffectiveOn and ExpiresOn columns.
11/01/2007	Biju Basheer	Changed to reflect new schema
01/25/2008	Paul Hunter		Renamed to work with the new schema, parameters and
							purporse.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error	int
,	@proc	varchar(255)

select	@error	= 0
	,	@proc	= db_name() + '.' + object_name(@@procId) + '.';

select	pl.PlayListId
	,	l.FlashFileId
	,	l.Sequence
	,	l.IsEnabled
	,	f.FlashFile
	,	f.RunLength
	,	f.Description
	,	f.EffectiveOn
	,	f.ExpiresOn
	,	f.IsAvailable
	,	pl.AspectRatio
	,	pl.PlayList
from	mkt.PlayList			pl
left join
		mkt.FlashFilePlayList	l
		on	l.PlayListId = pl.PlayListId
left join
		mkt.FlashFile			f
		on	l.FlashFileId = f.FlashFileId
where	pl.PlaylistId = isnull(@PlayListId, pl.PlayListId)
order by
		l.Sequence;

set	@error = @@error;

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc;

return @error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[PlayList_getFlashFiles]  TO [wa_Marketing]
GO