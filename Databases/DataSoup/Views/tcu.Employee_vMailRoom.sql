use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vMailRoom]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vMailRoom]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_vMailRoom
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/28/2008
Purpose  :	Used to produce the Mail Room file after the new HR file is loaded.
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/03/2009	Paul Hunte		Changed to ANSI SQL92 query format.
————————————————————————————————————————————————————————————————————————————————
*/

select	'FirstName'		as FirstName
	,	'LastName'		as LastName
	,	'Telephone'		as Telephone
	,	'Ext'			as Ext
	,	'Location'		as Location
	,	'Department'	as Department
	,	'Address'		as Address
	,	'City'			as City
	,	'State'			as State
	,	'ZipCode'		as ZipCode

union all

select	PreferredName
	,	LastName
	,	Telephone
	,	isnull(case right(Telephone, 4) when Ext then '' else Ext end, '') 
	,	'"' + isnull(Location, '') + '"'
	,	'"' + isnull(Department, '') + '"'
	,	'"' + isnull(Address1, '') + isnull(', ' + Address2, '') + '"'
	,	isnull(City, '')
	,	isnull(State, '')
	,	isnull(ZipCode, '')
from	tcu.Employee
where	IsDeleted	= 0;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO