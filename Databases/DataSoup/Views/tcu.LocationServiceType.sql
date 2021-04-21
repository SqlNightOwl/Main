use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationServiceType]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[LocationServiceType]
GO
setuser N'tcu'
GO
CREATE view tcu.LocationServiceType
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2007
Purpose  :	Indexed view of the Available Location Service Types.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	ServiceTypeId	= v.ReferenceValueId
	,	ServiceType		= v.Description
	,	IsPublic		= case isnumeric(v.ExtendedData1) when 1 then cast(v.ExtendedData1 as int) else 0 end
	,	ServiceTypeCode	= v.ReferenceCode
	,	v.Sequence
from	tcu.Reference		r
join	tcu.ReferenceValue	v
		on	r.ReferenceId = v.ReferenceId
where	r.ReferenceObject	= 'LocationService.ServiceType'
and		r.IsEnabled			= 1
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO