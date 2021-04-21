use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[PlayList_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[PlayList_ins]
GO
setuser N'mkt'
GO
create procedure mkt.PlayList_ins
	@PlayList		varchar(50)
,	@AspectRatio	decimal(5,3)
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	11/06/2005
Purpose  :	Inserts/Updates a record in the mktFlashFilePlayList table based upon
			the primary key.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@nextId	int

set	@error	= 0

-- Find the next possible value for PlayListId
select	top 1
		@nextId	= min(PlayListId) + 1
from	mkt.PlayList
where	PlayListId not in ( select PlayListId - 1 from mkt.PlayList )

--	do the insert
insert 	mkt.PlayList
	(	PlayListId
	,	PlayList
	,	AspectRatio
	)
values
	(	@nextId
	,	@PlayList
	,	@AspectRatio		)

select	@error	= @@error

PROC_EXIT:

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[PlayList_ins]  TO [wa_Marketing]
GO