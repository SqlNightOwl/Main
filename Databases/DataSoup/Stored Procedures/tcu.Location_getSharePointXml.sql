use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_getSharePointXml]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Location_getSharePointXml]
GO
setuser N'tcu'
GO
create procedure tcu.Location_getSharePointXml
	@LocationType	varchar(10)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/03/2005
Purpose  :	Creates Xml output for consumption by our SharePoint portal.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@type2		varchar(10)

--	include the Drive Thru for Banches
set	@type2	=	case @LocationType
				when 'Branch' then 'Drive Thru'
				else '' end

select	Tag		= 1
	,	Parent	= null
	,	[regions!1!node]			=	null
	,	[region!2!region]			=	null
	,	[location!3!branch]			=	null
	,	[location!3!location]		=	null
	,	[location!3!isPublic]		=	null
	,	[location!3!address1]		=	null
	,	[location!3!address2]		=	null
	,	[location!3!address3]		=	null
	,	[location!3!phone]			=	null
	,	[location!3!fax]			=	null
	,	[hours!4!type]				=	null
	,	[hours!4!daysOfWeek!hide]	=	null
	,	[hours!4!days]				=	null
	,	[hours!4!hours]				=	null

union all

select	distinct
		Tag		= 2
	,	Parent	= 1
	,	[regions!1!node]			=	null
	,	[region!2!region]			=	l.Region
	,	[location!3!branch]			=	null
	,	[location!3!location]		=	null
	,	[location!3!isPublic]		=	null
	,	[location!3!address1]		=	null
	,	[location!3!address2]		=	null
	,	[location!3!address3]		=	null
	,	[location!3!phone]			=	null
	,	[location!3!fax]			=	null
	,	[hours!4!type]				=	null
	,	[hours!4!daysOfWeek]		=	null
	,	[hours!4!days]				=	null
	,	[hours!4!hours]				=	null
from	tcu.Location	l
where	l.LocationType	= @LocationType
and		l.IsActive		= 1

union all

select	Tag		= 3
	,	Parent	= 2
	,	[regions!1!node]			=	null
	,	[region!2!region]			=	l.Region
	,	[location!3!branch]			=	l.LocationCode
	,	[location!3!location]		=	l.Location
	,	[location!3!isPublic]		=	l.HasPublicAccess
	,	[location!3!address1]		=	l.Address1
	,	[location!3!address2]		=	coalesce(nullif(l.Address2, ''), l.City + ', ' + l.State + '  ' + l.ZipCode)
	,	[location!3!address3]		=	case len(isnull(l.Address2, ''))
										when 0 then ''
										else l.City + ', ' + l.State + '  ' + l.ZipCode
										end
	,	[location!3!phone]			=	left(l.Phone, 3) + '.' + substring(l.Phone, 4, 3) + '.' + right(l.Phone, 4)
	,	[location!3!fax]			=	left(l.Fax, 3) + '.' + substring(l.Fax, 4, 3) + '.' + right(l.Fax, 4)
	,	[hours!4!type]				=	null
	,	[hours!4!daysOfWeek]		=	null
	,	[hours!4!days]				=	null
	,	[hours!4!hours]				=	null
from	tcu.Location	l
where	l.LocationType	= @LocationType
and		l.IsActive		= 1

union all

select	Tag		= 4
	,	Parent	= 3
	,	[regions!1!node]			=	null
	,	[region!2!region]			=	l.Region
	,	[location!3!branch]			=	null
	,	[location!3!location]		=	l.Location
	,	[location!3!isPublic]		=	null
	,	[location!3!address1]		=	null
	,	[location!3!address2]		=	null
	,	[location!3!address3]		=	null
	,	[location!3!phone]			=	null
	,	[location!3!fax]			=	null
	,	[hours!4!type]				=	l.LocationType
	,	[hours!4!daysOfWeek]		=	h.DaysOfWeek
	,	[hours!4!days]				=	h.DaysOfOperation
	,	[hours!4!hours]				=	h.HoursOfOperation
from	tcu.Location			l
join	tcu.LocationHour_v	h
	on	l.LocationId	= h.LocationId
where	l.LocationType	in (@LocationType, @type2)
and		l.IsActive		= 1

order by
 		[region!2!region]
 	,	[location!3!location]
 	,	[hours!4!type]
 	,	[hours!4!daysofweek!hide]

for xml explicit
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO