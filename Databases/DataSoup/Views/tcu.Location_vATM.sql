use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_vATM]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Location_vATM]
GO
setuser N'tcu'
GO
CREATE view tcu.Location_vATM
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/01/2008
Purpose  :	Returns a list of all available ATMs from the tcu.Location table and
			indicates the ServiceLocation as Branch (connected to a Branch) or 
			Remote (not connected to a Branch).
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/14/2010	Paul Hunter		Added logic to indicate which ATMs to exclude from
							Active Branch calculations.
————————————————————————————————————————————————————————————————————————————————
*/

select	a.LocationId
	,	a.Location
	,	a.LocationType
	,	a.LocationSubType
	,	a.LocationCode
	,	a.OrgNbr							as NetworkNodeNbr
	,	isnull(b.LocationType, 'Remote')	as ServiceLocation
	,	a.Address1
	,	a.Address2
	,	a.City
	,	a.State
	,	a.ZipCode
	,	a.ParentId
	,	a.IsActive
	,	a.HasPublicAccess
	,	isnull(b.ActiveBranch, 'RA')		as ActiveBranch
	,	isnull(x.IncludeInActiveBranch, 1)	as IncludeInActiveBranch
from	tcu.Location	a
left join
	(	select	LocationId, LocationType, ActiveBranch = cast(OrgNbr as varchar(6))
		from	tcu.Location
		where	LocationType = 'Branch'
		and		OrgNbr > 0
	)	b	on	a.ParentId = b.LocationId
left join
	(	select	LocationId, 0 as IncludeInActiveBranch
		from	tcu.LocationService
		where	ServiceTypeId = 2278	--	ReferencId for Exclude from Active Branch
	)	x	on	a.LocationId = x.LocationId
where	a.LocationType	= 'ATM'
and		a.OrgNbr		> 0;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO