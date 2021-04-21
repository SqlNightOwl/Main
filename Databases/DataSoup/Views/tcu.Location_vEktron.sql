use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_vEktron]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Location_vEktron]
GO
setuser N'tcu'
GO
CREATE view tcu.Location_vEktron
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/22/2008
Purpose  :	Retrieves only the columns which are used by the Ektron server in the 
			tcuCore database to support displaying Locations.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	LocationId
	,	Location
	,	LocationType
	,	LocationSubType
	,	Address1
	,	Address2
	,	City
	,	State
	,	ZipCode
	,	Phone
	,	Fax
	,	ParentId
	,	Region
	,	Directions
	,	WebNotice
	,	Latitude
	,	Longitude
	,	IsActive
	,	HasPublicAccess
from	tcu.Location
where	LocationType	in ('ATM', 'Branch', 'Drive Thru')
and		IsActive		= 1
and		HasPublicAccess	= 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO