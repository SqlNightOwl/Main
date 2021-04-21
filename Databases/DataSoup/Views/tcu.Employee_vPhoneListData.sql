use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_vPhoneListData]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Employee_vPhoneListData]
GO
setuser N'tcu'
GO
CREATE view tcu.Employee_vPhoneListData
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/24/2008
Purpose  :	Returns the Employee/Department information for use in producing the
			xml nodes for SharePoint.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
11/03/2009	Paul Hunter		Changed to only include active locations.
————————————————————————————————————————————————————————————————————————————————
*/

select	Level				= 1
		--	LOCATION
	,	LocationId
	,	LocationType
	,	Location			= Location + case LocationType when 'Branch' then ' Branch' else '' end
	,	Address1			= isnull(Address1	, '')
	,	Address2			= isnull(Address2	, '')
	,	City				= isnull(City		, '')
	,	State				= isnull(State		, '')
	,	ZipCode				= isnull(ZipCode	, '')
	,	LocationPhone		= tcu.fn_FormatPhone(Phone)
	,	LocationFax			= tcu.fn_FormatPhone(Fax)
	,	LocationTollFree	= tcu.fn_FormatPhone(TollFree)
		--	HOURS
	,	dow					= null
	,	HoursFor			= null
	,	Days				= null
	,	Times				= null
		--	EMPLOYEE
	,	PersonId			= null
	,	FirstName			= null
	,	LastName			= null
	,	Title				= null
	,	Sequence			= null
	,	Department			= null
	,	EmployeePhone		= null
	,	EmployeeFax			= null
	,	Email				= null
	,	IsManager			= null 
from	tcu.Location
where	LocationId	in ( select distinct LocationId from tcu.LocationDepartment )
and		IsActive	= 1

union all

select	Level				= 2
		--	LOCATION
	,	LocationId
	,	LocationType
	,	Location + case LocationType when 'Branch' then ' Branch' else '' end
	,	Address1			= null
	,	Address2			= null
	,	City				= null
	,	State				= null
	,	ZipCode				= null
	,	LocationPhone		= null
	,	LocationFax			= null
	,	LocationTollFree	= null
		--	HOURS
	,	DaysOfWeek			--	dow
	,	HourType			--	type
	,	DaysOfOperation		--	days
	,	HoursOfOperation	--	hours
		--	EMPLOYEE
	,	PersonId			= null
	,	FirstName			= null
	,	LastName			= null
	,	Title				= null
	,	Sequence			= null
	,	Department			= null
	,	EmployeePhone		= null
	,	EmployeeFax			= null
	,	Email				= null
	,	IsManager			= null 
from(	select	LocationId
			,	Location
			,	LocationType
			,	HourType	= case LocationType when 'Branch' then 'Lobby' else 'Office' end
			,	DaysOfWeek
			,	DaysOfOperation
			,	HoursOfOperation
		from	tcu.LocationHour_v	h
		where	LocationId in ( select LocationId from tcu.LocationDepartment )
	union all
		select	p.LocationId
			,	p.Location
			,	p.LocationType
			,	HourType	= 'Drive Thru' 
			,	h.DaysOfWeek + 1000
			,	h.DaysOfOperation
			,	h.HoursOfOperation
		from	tcu.Location		dt
		join	tcu.Location		p
				on	dt.ParentId	= p.LocationId
		join	tcu.LocationHour_v	h
				on	dt.LocationId	= h.LocationId
		where	dt.ParentId		in ( select LocationId from tcu.LocationDepartment )
		and		dt.LocationType	= 'Drive Thru'
	)	hrs

union all

select	Level		= 3
		--	LOCATION
	,	l.LocationId
	,	l.LocationType
	,	l.Location + case l.LocationType when 'Branch' then ' Branch' else '' end
	,	Address1			= null
	,	Address2			= null
	,	City				= null
	,	State				= null
	,	ZipCode				= null
	,	LocationPhone		= null
	,	LocationFax			= null
	,	LocationTollFree	= null
		--	HOURS
	,	dow					= 9999
	,	HoursFor			= null
	,	Days				= null
	,	Times				= null
		--	EMPLOYEE
	,	PersonId			= isnull(cast(e.PersonId as varchar), '')
	,	FirstName			= e.PreferredName
	,	e.LastName
	,	Title				= isnull(e.JobTitle	 , '')
	,	ld.Sequence
	,	Department			= isnull(e.Department, '')
	,	EmployeePhone		= isnull(e.Telephone , '')
	,	EmployeeFax			= isnull(e.Fax		 , '')
	,	Email				= isnull(e.Email	 , '')
	,	case left(e.EPMSCode, 3)
		when 'MGR' then '1'
		when 'SLT' then '1'
		else '0' end									--	isManager
from	tcu.LocationDepartment	ld
join	tcu.Employee			e
		on	ld.DepartmentCode = e.DepartmentCode
join	tcu.Location			l
		on	ld.LocationId = l.LocationId
where	e.IsDeleted = 0
and		l.IsActive	= 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO