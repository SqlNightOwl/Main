use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationHour_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[LocationHour_v]
GO
setuser N'tcu'
GO
CREATE view tcu.LocationHour_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/01/2006
Purpose  :	Creates a list of the hours of operations for the Location.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/23/2007	Paul Hunter		Changed upper bound for DaysOfWeek display to 1024.
05/30/2008	Paul Hunter		Added 1048576 to DaysOfWeek (Facility Hours).
06/11/2008	Paul Hunter		Added Location and LocationType to the output.
11/03/2009	Paul Hunter		Changed to only return active Locaitons.
————————————————————————————————————————————————————————————————————————————————
*/

select	h.LocationHourId
	,	h.LocationId
	,	l.Location
	,	l.LocationType
	,	h.DaysOfWeek
	,	h.FromHour
	,	h.ToHour
	,	FromHourDisplay		=	case
								when h.DaysOfWeek in (1, 1024, 1048576) then null
								else lower(ltrim(right(cast(h.FromHour as varchar), 7)))
								end
	,	ToHourDisplay		=	case
								when h.DaysOfWeek in (1, 1024, 1048576) then null
								else lower(ltrim(right(cast(h.ToHour as varchar), 7)))
								end
	,	DaysOfOperation		=	tcu.fn_Frequency(h.DaysOfWeek)
	,	HoursOfOperation	=	case
								when h.DaysOfWeek in (1, 1024, 1048576) then null
								else lower(ltrim(right(cast(h.FromHour as varchar), 7)) + ' - '
									+ ltrim(right(cast(h.ToHour as varchar), 8)))
								end
from	tcu.LocationHour	h
join	tcu.Location		l
		on	h.LocationId = l.LocationId
where	l.IsActive = 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO