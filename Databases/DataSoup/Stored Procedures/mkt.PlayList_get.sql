use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[PlayList_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[PlayList_get]
GO
setuser N'mkt'
GO
create procedure mkt.PlayList_get
	@PlayListId	tinyint			= null
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	10/31/2007
Purpose  :	Retrieves all PlayLists or the specified one.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/25/2008	Paul Hunter		Renamed to use the existing naming policies and the
							new schema.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

select	PlayListId
	,	PlayList
	,	AspectRatio
from	mkt.PlayList
where	PlayListId = isnull(@PlayListId, PlayListId)

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
GRANT  EXECUTE  ON [mkt].[PlayList_get]  TO [wa_Marketing]
GO