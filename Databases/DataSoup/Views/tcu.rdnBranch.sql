use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[rdnBranch]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[rdnBranch]
GO
setuser N'tcu'
GO
CREATE view tcu.rdnBranch
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/10/2007
Purpose  :	Returns list of Premier Location Codes to the OSI Org Number for the
			Raddon Active Branch process.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

--	Include in Raddon Cross Reference
select	l.LocationCd
	,	l.Location
	,	case
		when l.OrgNbr < 10 then '0'
		else ''
		end	+ cast(l.OrgNbr as varchar(9)) as OrgNbr
from	tcu.LocationService	s
join	tcu.Location		l
		on	s.LocationId = l.LocationId
		--	Include in Raddon Cross Reference
where	s.ServiceTypeId = 526;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO