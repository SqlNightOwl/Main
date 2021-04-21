use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFile_del]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[FlashFile_del]
GO
setuser N'mkt'
GO
create procedure mkt.FlashFile_del
	@FlashFileId	int
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	09/11/2006
Purpose  :	Deletes a record from the mktFlashFile table and all related records
			from the mktFlashPlayList table based upon the primary key.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
01/25/2008	Fijula Kuniyil	Modified to fit into new schema
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

declare @temp table
	(	PlayListId	int		not null
	,	Seq			tinyint	not null
	)

insert @temp
	(	PlayListId
	,	Seq)
select	PlayListId
	,	Sequence
from	mkt.FlashFilePlayList
where	FlashFileId	= @FlashFileId

delete	mkt.FlashFilePlayList
where	FlashFileId = @FlashFileId

if exists ( select 1 from @temp )
begin
	update	m
	set		Sequence = m.Sequence - 1
	from	mkt.FlashFilePlayList	m
	cross join	@temp					t
	where	m.PlayListId	= t.PlayListId
	and		m.Sequence		> t.Seq
end

--	now it's ok to delete the file
delete	mkt.FlashFile
where	FlashFileId	= @FlashFileId

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
GRANT  EXECUTE  ON [mkt].[FlashFile_del]  TO [wa_Marketing]
GO