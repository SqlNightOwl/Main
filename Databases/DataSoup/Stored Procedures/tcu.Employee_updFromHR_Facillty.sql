use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_updFromHR_Facillty]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_updFromHR_Facillty]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_updFromHR_Facillty
	@Detail	varchar(4000)	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/16/2009
Purpose  :	Adds new Facilities from the HR File into the Facility table.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@count	int
,	@now	datetime
,	@result	int
,	@state	char(2)
,	@user	varchar(25)

select	@count	= 0
	,	@now	= getdate()
	,	@result	= 0
	,	@state	= 'TX'
	,	@user	= 'HR Import'

begin try
	--	add any missing facilities...
	insert	tcu.Facility
		(	FacilityCd
		,	LocationId
		,	Facility
		,	Address1
		,	Address2
		,	City
		,	[State]
		,	ZipCd
		,	Latitude
		,	Longitude
		,	HasPublicAccess
		,	IsActive
		,	CreatedBy
		,	CreatedOn
		)
	select	e.LOC_CODE			as FacilityCd
		,	min(m.LocationId)
		,	min(e.LOC_NAME)
		,	min(e.LOC_ADDRESS1)
		,	min(e.LOC_ADDRESS2)
		,	min(e.LOC_CITY)
		,	@state
		,	left(min(e.LOC_ZIP_POST_CODE), 5)
		,	min(m.Latitude)
		,	min(m.Longitude)
		,	1					as HasPublicAccess
		,	1					as IsActive
		,	@user				as CreatedBy
		,	@now				as CreatedOn
	from	tcu.Employee_load	e
	left join
			tcu.Facility		f
			on	e.LOC_CODE = f.FacilityCd
	cross apply
		(	select	LocationId, Latitude, Longitude
			from	tcu.Facility
			where	FacilityCd = 'MAIN'	)	m
	where	f.FacilityCd is null
	group by e.LOC_CODE
	order by e.LOC_CODE;

	select	@count	= @@rowcount
		,	@result	= @@error;

	if @count > 0
		set @detail = @detail + 'There were ' + cast(@count as varchar(10))
					+ ' new Facilities added from the most recent HR Sync file.<br/>';
end try
begin catch
	--	collect the error details...
	exec tcu.ErrorDetail_get @Detail out;
	set	@result = 1;
end catch;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO