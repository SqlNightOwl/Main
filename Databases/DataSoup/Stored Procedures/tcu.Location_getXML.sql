use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_getXml]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Location_getXml]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Location_getXml
	@city		varchar(25)	= null
,	@zip		char(5)		= null
,	@type		varchar(10)	= null
,	@distance	smallint	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/24/2004
Purpose  :	Returns an XML document containing Texans Locations matching the
			criteria provided.  This was primaryly created to support returning
			this data thru a Web Service.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/24/2009	Paul Hunter		Fixed condition where if invalid informaiton is passed
							and no locations are matched, it still returns the
							root Locations node (<Locations></Locations>)
01/07/2010	Paul Hunter		Added icon attribute to the <Location> node.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@atm	varchar(10)
,	@branch	varchar(10)
,	@dt		varchar(10)
,	@first	int
,	@lat	decimal(9, 6)
,	@lon	decimal(9, 6)

declare	@locations	table
	(	id			int			primary key
	,	location	varchar(75)	not null
	,	type		varchar(10)	not null
	,	distance	smallint	not null
	,	parentId	int			null
	,	icon		varchar(6)	not null
	);

--	clean up the parameters and initialize the driveThru variable..
select	@dt			= 'Drive Thru'
	,	@city		= nullif(rtrim(@city)		, '')
	,	@zip		= nullif(rtrim(@zip)		, '')
	,	@type		= isnull(nullif(rtrim(@type), ''), 'both')
	,	@distance	= case when isnull(@distance, 0) < 1 then 5 else @distance end;

--	handle atm/branch specific searches...
select	@atm		= case @type when 'branch'	then null else 'atm' end
	,	@branch		= case @type when 'atm'		then null else 'branch' end;

if coalesce(@city, @zip, '^') = '^'
begin
	--	no city or zip was provided so get everything within 500 miles of Texans Credit Unions' zip
	set	@zip		= '75081';
	set	@distance	= 500;
end;

--	if you have a zip then use that over the city...
if @zip is not null set @city = null;

--	collect the average latitude/longitude for the location provided...
select	@lat	= abs(avg(z.Latitude))
	,	@lon	= abs(avg(z.Longitude))
from	tcu.ZipCity	c
join	tcu.ZipCode	z
		on	c.ZipCode = z.ZipCode
where((	c.City		= @city
	and c.State		= 'TX')	or @city	is null	)
and	 (	z.ZipCode	= @zip	or @zip		is null	)

--	collect the locations matching the criteria provided...
insert	@locations
select	LocationId
	,	tcu.fn_XmlEncode(Location)
	,	LocationType
	,	round(tcu.fn_Distance(@lat, @lon, Latitude, Longitude), 0)
	,	isnull(ParentId, LocationId)
	,	case
		when LocationType = 'branch' then 'both'
		when LocationType = 'atm'
		 and ParentId		is null	 then 'atm'
		else 'branch' end
from	tcu.Location
where( (LocationType	= @atm	and	ParentId is null	)	--	return atms
	or (LocationType	= @branch						)	--	return branches
	or (LocationType	= @dt	and @branch	 = 'branch'	)	--	include the drive thru's if branch is specified
	 )
and		IsActive		= 1
and		HasPublicAccess	= 1;

--	remove locations not within the requested distance
delete	@locations
where	distance > @distance;

--	collect the Id of the first Locatiton to be displayed...
select	top 1 @first = id
from	@locations
order by distance, location;

if exists ( select top 1 * from @locations )
begin

	select	Record
	from(	select	top 1
					'<Locations>'	as Record
				,	0				as Distance
				,	null			as Location
				,	null			as Sequence
				,	null			as DaysOfWeek
				,	null			as LocationType
			from	@locations

			union all

			select	case l.LocationId
					when @first then ''	--	you don't need a closing tag for the first location.
					else '</Location>'	--	all others do need the tag...
					end
				+	'<Location '
				+	'distance="'	+ cast(t.distance as varchar(10))			+ '" '
				+	'type="'		+ l.LocationType							+ '" '
				+	'name="'		+ t.location								+ '" '
				+	'address1="'	+ tcu.fn_XmlEncode(l.Address1)				+ '" '
				+	'address2="'	+ tcu.fn_XmlEncode(isnull(l.Address2, ''))	+ '" '
				+	'city="'		+ l.City									+ '" '
				+	'state="'		+ l.State									+ '" '
				+	'zip="'			+ left(l.ZipCode, 5)						+ '" '
				+	'icon="'		+ t.icon									+ '" '
				+	'phone="972.348.2000" '
				+	'tollFree="800.843.5295">'	as Record
				,	t.distance
				,	l.Location
				,	0							as Sequence
				,	0							as DaysOfWeek
				,	l.LocationType
			from	@locations		t
			join	tcu.Location	l
					on	t.id = l.LocationId
			where	t.type < @dt

			union all

			select	'<Service sequence="' + cast(s.Sequence as varchar(5)) 
				+	'" service="' + tcu.fn_XmlEncode(s.ServiceType)
				+	'" />'		as Record
				,	t.distance
				,	t.location
				,	s.Sequence
				,	1			as DaysOfWeek
				,	''			as LocationType
			from	@locations				t
			join	tcu.LocationService_v	s
					on	t.id = s.LocationId
			where	t.type		< @dt
			and		s.IsPublic	= 1

			union all

			select	'<Hours for="' +
						case h.LocationType	
						when 'Branch' then 'Lobby'
						else h.LocationType end
				+	'" days="' + cast(h.DaysOfWeek as varchar(10))
				+	'" hours="' + tcu.fn_XmlEncode(DaysOfOperation + isnull(': ' + HoursOfOperation, ''))
				+	'" />'						as Record
				,	t.distance
				,	t.location
				,	99							as Sequence
				,	h.DaysOfWeek
				,	case h.LocationType	
					when 'Branch' then 'Lobby'
					else h.LocationType end		as LocationType
			from	@locations			t
			join	tcu.LocationHour_v	h
					on	t.id = h.LocationId

			union all

			select	top 1
					'</Location>'	--	close out the Location
				+	'</Locations>'	as Record
				,	9999			as Distance
				,	''				as Location
				,	9999			as Sequence
				,	9999			as DaysOfWeek
				,	''				as LocationType
			from	@locations
		)	data
	order by
			Distance
		,	Location
		,	Sequence
		,	LocationType desc
		,	DaysOfWeek
end;
else
begin
	select '<Locations></Locations>';
end;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Location_getXml]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [tcu].[Location_getXml]  TO [wa_Services]
GO