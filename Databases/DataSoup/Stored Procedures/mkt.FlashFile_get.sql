use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFile_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[FlashFile_get]
GO
setuser N'mkt'
GO
CREATE procedure mkt.FlashFile_get
	@FlashFileId	int				= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	08/16/2006
Purpose  :	Retrieves mktFlashFile and mktFlashPlayList information from the
			tables based upon the optional location id.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
02/26/2007	Paul Hunter		Added EffectiveOn and ExpiresOn coulumns
11/11/2007	Biju Basheer	Updated to reflect changes to schema
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

select	distinct
		f.FlashFileId
	,	f.FlashFile
	,	f.RunLength
	,	f.Description
	,	f.EffectiveOn
	,	f.ExpiresOn
	,	f.IsAvailable
	,	f.AspectRatio
	,	InUse		= cast(case coalesce(c.itemCount, 0) when 0 then 0 else 1 end as bit)
from	mkt.FlashFile	f
left join
	(	select	FlashFileId, itemCount = count(1)
		from	mkt.FlashFilePlayList with (nolock)
		where	IsEnabled = 1 group by FlashFileId
	)	c	on f.FlashFileId = c.FlashFileId
where	f.FlashFileId	= isnull(@FlashFileId, f.FlashFileId)

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
GRANT  EXECUTE  ON [mkt].[FlashFile_get]  TO [wa_Marketing]
GO