use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationService_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[LocationService_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.LocationService_get
	@LocationId	int				= null
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/11/2007
Purpose  :	Retrieves listed services for the specified Location Id. 
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

select	ls.LocationId
	,	ls.ServiceTypeId
	,	ls.ServiceType
	,	ls.IsPublic
	,	ls.Sequence
	,	ls.IsVirtual
	,	sc.NumberOfServices
from	tcu.LocationService_v	ls
join(	select	LocationId, NumberOfServices = count(1)
		from	tcu.LocationService_v
		where	IsPublic = 1
		group by LocationId
	)	sc	on	ls.LocationId = sc.LocationId
where	ls.LocationId	= isnull(@LocationId, ls.LocationId)
and		ls.IsPublic		= 1
order by
		ls.LocationId
	,	ls.Sequence
	,	ls.ServiceType

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