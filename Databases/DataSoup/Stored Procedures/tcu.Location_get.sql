use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Location_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Location_get
	@LocationId			int				= null
,	@LocationTypeList	varchar(100)	= null
,	@LocationCode		varchar(10)		= null
,	@ParentId			int				= null
,	@Region				varchar(50)		= null
,	@IsActive			tinyint			= null
,	@HasPublicAccess	tinyint			= null
,	@errmsg				varchar(255)	= null	output	-- in case of error
,	@debug				tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/02/2005
Purpose  :	Retrieves Location(s) based upon the criteria provided.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/03/2006	Paul Hunter		Added WebNotice column.
08/24/2006	Paul Hunter		Added IsActive and HasPublicAccess as parameters.
10/31/2007	Biju Basheer	Removed reference to unused columns
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error	int
,	@proc	varchar(255);

set	@error	= 0;
set	@proc	= db_name() + '.' + object_name(@@procid) + '.';

set	@LocationTypeList = isnull(rtrim(@LocationTypeList), '');

select	LocationId
	,	Location
	,	LocationType
	,	LocationSubType
	,	LocationCode
	,	OrgNbr
	,	AddressCode
	,	Address1
	,	Address2
	,	City
	,	State
	,	ZipCode
	,	Phone
	,	Fax
	,	ParentId
	,	ManagerId
	,	DepartmentCode
	,	PlayListId
	,	Region
	,	Directions
	,	WebNotice
	,	Latitude
	,	Longitude
	,	CashBox
	,	DirectPostAcctNbr
	,	IsActive
	,	HasPublicAccess
from	tcu.Location
where	case len(@LocationTypeList)
		when 0 then 1
		else charindex(LocationType, @LocationTypeList)
		end	> 0
and	(	LocationId			= @LocationId		or @LocationId		is null)
and	(	LocationCode		= @LocationCode		or @LocationCode	is null)
and	(	Region				= @Region			or @Region			is null)
and	(	isnull(ParentId
			, LocationId)	= @ParentId			or @ParentId		is null)
and	(	IsActive			= @IsActive			or @IsActive		is null)
and	(	HasPublicAccess		= @HasPublicAccess	or @HasPublicAccess is null);

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
GRANT  EXECUTE  ON [tcu].[Location_get]  TO [wa_Marketing]
GO