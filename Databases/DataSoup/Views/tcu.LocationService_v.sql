use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationService_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[LocationService_v]
GO
setuser N'tcu'
GO
CREATE view tcu.LocationService_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2007
Purpose  :	View of both assigned and virtual services at a Location.  Virtual
			services come from other Locations related to a parent such as an ATMs
			or a Drive-Thru.  Assigned services are those assigned by Marketing
			as additional servies or features of a location such as night despository
			or Texans Financial offices.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/23/2009	Paul Hunter		Added Location and Location type to the results
01/13/2010	Paul Hunter		Added "full service/non-deposit taking" to the ATM
							description.
————————————————————————————————————————————————————————————————————————————————
*/

--	assigned services
select	s.LocationId
	,	l.Location
	,	l.LocationType
	,	s.ServiceTypeId
	,	t.ServiceType
	,	t.IsPublic
	,	t.Sequence
	,	IsVirtual	= 0
from	tcu.LocationService		s
join	tcu.Location			l
		on	s.LocationId = l.LocationId
join	tcu.LocationServiceType	t
		on	s.ServiceTypeId = t.ServiceTypeId

union all

--	virutal services based upon "related" locations
select	v.LocationId
	,	v.Location
	,	v.LocationType
	,	0						as ServiceTypeId
	,	case v.LocationSubType
		when 'Walk Up' then ''
		else v.LocationSubType	+ ' '
		end
	+	v.LocationType
	+	case
		when v.Items < 2 then ''
		else 's'
		end
	+	case
		when v.AcceptDeposits > 0 then ' (Full Service)'
		else ' (Non-Deposit-Taking)'
		end						as ServiceType
	,	v.IsPublic
	,	case v.LocationSubType
		when 'Drive Up'	then 0
		when 'Walk Up'	then 0
		else 99 end				as Sequence
	,	1						as IsVirtual
from (	--	virtual table of ATMs
		select	l.ParentId				as LocationId
			,	p.Location
			,	l.LocationType
			,	l.LocationSubType
			,	l.HasPublicAccess		as IsPublic
			,	count(1)				as Items
			,	sum(l.AcceptsDeposits)	as AcceptDeposits
		from	tcu.Location	l
		join	tcu.Location	p
				on	l.ParentId = p.LocationId
		where	l.LocationType	='ATM'
		and		l.ParentId		is not null
		and		l.IsActive		= 1
		group by
				l.ParentId
			,	p.Location
			,	l.LocationType
			,	l.LocationSubType
			,	l.HasPublicAccess
	)	v;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO