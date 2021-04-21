use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Country]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Country]
GO
setuser N'tcu'
GO
CREATE view tcu.Country
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/05/2006
Purpose  :	List of Countries
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	CountryCode		= left(v.ReferenceCode, 2)
	,	Country			= v.ReferenceValue
	,	PhoneFormat		= v.ExtendedData1
	,	PostCodeFormat	= v.ExtendedData2
from	tcu.Reference		r
join	tcu.ReferenceValue	v
		on	r.ReferenceId = v.ReferenceId
where	r.ReferenceObject	= 'Country'
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO