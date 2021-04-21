use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[PlayList_getLocations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[PlayList_getLocations]
GO
setuser N'mkt'
GO
CREATE procedure mkt.PlayList_getLocations
	@PlayListId	tinyint			= null
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	11/01/2007
Purpose  :	Retrieves record(s) from the mktFlashFilePlayList table based upon the
			PlayListId.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/25/2008	Paul Hunter		Changed parameter data type and added location type
							for the Drive Thru.
06/24/2009	Paul Hunter		Changed IsInPlayListo to return Boolean (1/0)
02/18/2009	Paul Hunter		Removed criteria for IsActive branches.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error	int
,	@proc	varchar(255)

select	@error	= 0
	,	@proc	= db_name() + '.' + object_name(@@procId) + '.';

select	l.LocationId
	,	l.Location
	,	l.LocationType
	,	l.PlayListId
	,	IsInPlayList	= cast(case l.PlayListId when @PlayListId then 1 else 0 end as bit)
	,	pl.AspectRatio
from	tcu.Location	l
left join
		mkt.PlayList	pl
		on	l.PlayListId = pl.PlayListId
where	l.LocationType	in ('Branch', 'Drive Thru')
order by
		l.Location;

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
GRANT  EXECUTE  ON [mkt].[PlayList_getLocations]  TO [wa_Marketing]
GO