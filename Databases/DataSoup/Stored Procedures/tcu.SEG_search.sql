use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[SEG_search]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[SEG_search]
GO
setuser N'tcu'
GO
CREATE procedure [tcu].[SEG_search]
	@SEG		varchar(100)	= null
,	@SegType	varchar(10)		= null
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/23/2006
Purpose  :	Retrieves record(s) from the tcuSEG table based upon the search
			criteria provided.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/08/2008	Paul Hunter		Converted to SQL 2005 schema
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

set	@SEG		= isnull(rtrim(@SEG + '%'), '%')
set	@SegType	= nullif(@SegType, 'both')

select	SegId
	,	SegNumber
	,	SEG
	,	SegType
	,	AKA
	,	IsOpen
	,	StockSymbol
	,	AccountNumberBase
	,	AccountNumberFamily
	,	AccountNumberCheckDigit
from	tcu.SEG
where	Seg		like @SEG
and		SegType	= isnull(@SegType, SegType)
and		IsOpen	= 1
order by
		Seg

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
GRANT  EXECUTE  ON [tcu].[SEG_search]  TO [wa_Services]
GO