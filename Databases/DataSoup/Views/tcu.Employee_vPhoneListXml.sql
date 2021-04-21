use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vPhoneListXml]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vPhoneListXml]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_vPhoneListXml
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/24/2008
Purpose  :	Returns the Employee/Department information for use by SharePoint as
			XML based nodes to be exported as the PhoneList.xml file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	LocationId	= -2
	,	dow			= 0
	,	Sequence	= 0
	,	Department	= cast('' as varchar(50))
	,	FirstName	= cast('' as varchar(50))
	,	LastName	= cast('' as varchar(50))
	,	Node		= cast('<?xml version="1.0" encoding="UTF-8"?>' as varchar(500))

union all

select	LocationId	= -1
	,	dow			= 0
	,	Sequence	= 0
	,	Department	= cast('' as varchar(50))
	,	FirstName	= cast('' as varchar(50))
	,	LastName	= cast('' as varchar(50))
	,	Node		= cast('<Locations>' as varchar(500))

union all

select	l.LocationId
	,	l.dow
	,	l.Sequence
	,	l.Department
	,	l.FirstName
	,	l.LastName
	,	Node		=	cast(
							case l.Level
							when 1 then	case l.LocationId when mm.firstId then '' else '</Location>' end
									+	'<Location Id="'		+ cast(l.LocationId as varchar) 
											+ '" Type="'		+ l.LocationType
											+ '" Name="'		+ tcu.fn_XmlEncode(l.Location)
											+ '" Address1="'	+ tcu.fn_XmlEncode(l.Address1)
											+ '" Address2="'	+ tcu.fn_XmlEncode(l.Address2)
											+ '" City="'		+ l.City
											+ '" State="'		+ l.State
											+ '" Zip="'			+ l.ZipCode
											+ '" Phone="'		+ l.LocationPhone
											+ '" Fax="'			+ l.LocationFax
											+ '" TollFree="'	+ l.LocationTollFree
											+ '">'
							when 2 then '<Hours dow="'	+ cast(l.dow as varchar)
											+ '" Type="'	+ l.HoursFor
											+ '" Days="'	+ tcu.fn_XmlEncode(l.Days)
											+ '" Times="'	+ tcu.fn_XmlEncode(l.Times)
											+ '" />'
							when 3 then	'<Employee PictureId="'		+ cast(l.PersonId as varchar)
											+'" FirstName="'		+ l.FirstName
											+'" LastName="'			+ l.LastName
											+'" Title="'			+ tcu.fn_XmlEncode(l.Title)
											+'" Sequence="'			+ cast(l.Sequence as varchar)
											+'" Group="'			+ tcu.fn_XmlEncode(l.Department)
											+'" Phone="'			+ l.EmployeePhone
											+'" Fax="'				+ l.EmployeeFax
											+'" Email="'			+ l.Email
											+'" IsManager="'		+ l.IsManager
											+'" />'
									+	case l.PersonId
										when lp.lastPersonId then '</Location>'
										else '' end
							end
						as varchar(500))
from	tcu.Employee_vPhoneListData	l
cross join
	(	--	determine the first LocationId that will show up in the file
		select	firstId	= min(LocationId)
		from	tcu.Employee_vPhoneListData
	)	as mm
cross join
	(	--	determine the last person of the last location that will show up
		select	top 1 lastPersonId = PersonId
		from	tcu.Employee_vPhoneListData
		where	LocationId	= (select max(LocationId) from tcu.Employee_vPhoneListData)
		--	NOTE:	The sort order below will need to change as the overall sort changes.
		order by Sequence	desc	
			,	Department	desc
			,	FirstName	desc
			,	LastName	desc
	)	as lp

union all

select	LocationId	= 9999
	,	dow			= 9999
	,	Sequence	= 255
	,	Department	= 'ZZZZ'
	,	FirstName	= 'ZZZZ'
	,	LastName	= 'ZZZZ'
	,	Node		= cast('</Locations>' as varchar(500));
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO