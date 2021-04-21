use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_TexansFinancialReferrals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_TexansFinancialReferrals]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_TexansFinancialReferrals
	@StartDate	datetime
,	@EndDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/01/2008
Purpose  :	Referrals made to Texans Financial.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
12/22/2008	Paul Hunter		Converted to ONYX 6.0 schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@iSiteId	int;

set	@iSiteId	= 1;
set @EndDate	= dateadd(day, 1, isnull(@EndDate, @StartDate));

exec ops.SSRSReportUsage_ins @@procid;

select	IncidentId			= i.secondary_id
	,	c.Customer
	,	Branch_Department	= br.parameter_desc
	,	BranchId			= i.department_did
	,	ReferredBy			= rtrim(refBy.[user_name])
	,	EnteredBy			= rtrim(entBy.[user_name])
	,	InsertDate			= i.insert_date
	,	AssignedTo			= fr.assigned_to
	,	ClosedBy			= rtrim(clsBy.[user_name])
	,	ClosedDate			= fc.closed_date
	,	StatusId			= i.status_did
	,	Status				= stat.parameter_desc
	,	ResCode				= i.resolution_did1
	,	ResolutionCode		= rc.parameter_desc
from	Onyx6_0.dbo.incident					i
join	Onyx6_0.cs.customer_v					c
		on	i.owner_id	= c.customer_id
		and	i.site_id	= c.site_id
join	Onyx6_0.dbo.reference_parameter_ml		br
		on	i.department_did	= br.reference_parameter_did
		and	i.site_id			= br.site_id
join	Onyx6_0.dbo.reference_parameter_ml		stat
		on	i.status_did		= stat.reference_parameter_did
		and	i.site_id		= stat.site_id
join	Onyx6_0.dbo.users						refBy
		on	i.insert_by	= refBy.[user_id]
		and i.site_id		= refBy.site_id

join	Onyx6_0.cs.incident_FirstReferred		fr
		on	i.incident_id	= fr.incident_id
		and i.site_id		= fr.site_id
join	Onyx6_0.dbo.users						txfn
		on	fr.assigned_to	= txfn.[user_id]
		and	fr.site_id		= txfn.site_id
join	Onyx6_0.dbo.users						entBy
		on	fr.insert_by	= entBy.[user_id]
		and	fr.site_id		= entBy.site_id
left join
		Onyx6_0.dbo.reference_parameter_ml		rc
		on	i.resolution_did1	= rc.reference_parameter_did
		and	i.site_id			= rc.site_id
left join
		Onyx6_0.cs.incident_FirstClosed			fc
		on	i.incident_id	= fc.incident_id
		and	i.site_id		= fc.site_id
left join	Onyx6_0.dbo.users					clsBy
		on	fc.insert_By	= clsBy.[user_id]
		and	fc.site_id		= clsBy.site_id
where	i.site_id			= @iSiteId
and		i.incident_category_did	= 3
and		i.update_date			between @StartDate
									and	@EndDate
and		txfn.group_code			= 'TexansFin'
and ( (	i.status_did		in (101512, 131, 102621) )	--	pending, referred or applicant
		--	or closed / won qualified
	or(	i.status_did		= 104	and
		i.resolution_did1	= 102770	)	-- 102623 - old value 
        --	or closed / lost, non qualified
	or(	i.status_did		= 104	and
		i.resolution_did1	= 102710	)	-- 102624 - old value
	)
order by
		br.parameter_desc
	,	refBy.[user_name]
	,	fc.closed_date;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO