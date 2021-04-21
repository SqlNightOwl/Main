use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[SEG_search]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[SEG_search]
GO
setuser N'mkt'
GO
create procedure mkt.SEG_search
	@SEG		varchar(100)	= null
,	@SegType	varchar(10)		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/08/2008
Purpose  :	Retrieves record(s) from the tcu.SEG table based upon the search
			criteria provided from the mkt schema.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
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

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO