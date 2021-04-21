use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFilePlayList_getLocations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[FlashFilePlayList_getLocations]
GO
setuser N'mkt'
GO
CREATE procedure mkt.FlashFilePlayList_getLocations
	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	11/16/2005
Purpose  :	Retrieves all valid record(s) from the mktFlashFilePlayList.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/26/2007	Paul Hunter		Added EffectiveOn and ExpiresOn logic to where clause.
10/31/2007	Biju Basheer	Changed to reflect changes to schema.
02/18/2010	Paul Hunter		Removed requiremnt to only return Active branches.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error	int
,	@proc	varchar(255)
,	@today	datetime

set	@error	= 0;
set	@proc	= db_name() + '.' + object_name(@@procId) + '.';
set	@today	= convert(char(10), getdate(), 121);

select	l.LocationId
	,	mx.Sequence
	,	ff.FlashFile
	,	ff.RunLength
	,	pl.PlayListId
	,	pl.PlayList
from	mkt.FlashFilePlayList	mx
join	mkt.FlashFile			ff
		on	mx.FlashFileId = ff.FlashFileId
join	mkt.PlayList			pl
		on	mx.PlayListId = pl.PlayListId
join	tcu.Location			l
		on	mx.PlayListId = l.PlayListId
where	mx.IsEnabled	= 1
and		ff.IsAvailable	= 1
and		@today			between isnull(ff.EffectiveOn, @today)
							and isnull(ff.ExpiresOn  , @today)
and		l.LocationType	in ('Branch', 'Drive Thru')
order by
		l.LocationId
	,	mx.Sequence;

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
GRANT  EXECUTE  ON [mkt].[FlashFilePlayList_getLocations]  TO [wa_Marketing]
GO