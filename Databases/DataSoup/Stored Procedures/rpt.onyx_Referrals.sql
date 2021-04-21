use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_Referrals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_Referrals]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_Referrals
	@StartDate		datetime
,	@EndDate		datetime
,	@Description	nvarchar(255)
,	@AssignedTo		nvarchar(80)	= null
,	@BranchId		int				= null
,	@ResCode		int				= null
,	@GroupId		nvarchar(85)	= null
,	@StatusId		int				= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	06/02/08
Purpose  :	Generic referral details report
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
07/09/2008	Neelima G		Added parameters BranchId, Resolution Code and GroupId
							to pull referrals based on these various criteria rather
							than just the AssignedTo parameter.
10/15/08	Neelima G		Added parameter StatusId.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set @EndDate	= dateadd(millisecond, -1, dateadd(day, 1, @EndDate));
set @AssignedTo	= nullif(@AssignedTo,'0');
set @BranchId	= nullif(@BranchId	, 0);
set @ResCode	= nullif(@ResCode	, 0);
set @GroupId	= nullif(@GroupId	,'0');
set @StatusId	= nullif(@StatusId	, 0);

select	a.BranchDepartment
	,	a.ReferringBranchDepartment
	,	a.ReferredBy
	,	a.IncidentId
	,	a.MemberName
	,	a.EnteredBy
	,	a.InsertDate
	,	a.AssignedTo
	,	a.ClosedBy
	,	a.ClosedDate
	,	a.ClosingBranchDepartment
	,	a.Status
	,	a.ResolutionCode
from(	select	BranchDepartment	= rp1.parameter_desc
			,	oi.ReferringBranchDepartment
			,	oi.ReferredBy
			,	IncidentId			= i.secondary_id
			,	MemberName			= c.customer
			,	EnteredBy			= rtrim(eu.[user_name])
			,	InsertDate			= i.insert_date
			,	AssignedTo			= rtrim(au.[user_name])
			,	ci.ClosedBy
			,	ci.ClosedDate
			,	ci.ClosingBranchDepartment
			,	Status				= rp2.parameter_desc
			,	i.status_did
			,	ResolutionCode		= rp3.parameter_desc
			,	i.resolution_did1
			,	i.assigned_to
			,	au.group_code
			,	oi.department_did
		from	Onyx6_0.dbo.incident		i
		join	Onyx6_0.cs.customer_v		c
				on	i.owner_id	= c.customer_id
				and	i.site_id	= c.site_id
		join	Onyx6_0.dbo.Users			eu
				on	i.Insert_By		= eu.[user_id]
				and i.site_id		= eu.site_id
		left join
				Onyx6_0.dbo.Users			au
				on	i.assigned_to	= au.[user_id]
				and i.site_id		= au.site_id
		left join
			(	--	collect originating information
				select	al.incident_id
					,	ReferredBy					= rtrim(u.[user_name])
					,	ReferringBranchDepartment	= rp.parameter_desc
					,	al.department_did	
				from	Onyx6_0.dbo.incident_audit_log		al
				join	Onyx6_0.dbo.users					u
						on	al.insert_by = u.[user_id]
				join	(	select	incident_id, insert_date = min(insert_date)
							from	Onyx6_0.dbo.incident_audit_log
							where	status_did = 101512	--	Referred
							group by incident_id
						) al1	on	al.incident_id	= al1.incident_id
								and al.insert_date	= al1.insert_date
				left join	--	branch/department
						Onyx6_0.dbo.reference_parameter_ml	rp
						on	al.department_did	= rp.reference_parameter_did
						and	al.site_id			= rp.site_id
				where	al.status_did = 101512			--	Referred
			)	oi	on	i.incident_id = oi.incident_id
		left join	
			(	--	collect closing information
				select	al.incident_id
					,	ClosedBy				= rtrim(u.[user_name])
					,	ClosedDate				= al.insert_date
					,	ClosingBranchDepartment	= rp.parameter_desc
				from	Onyx6_0.dbo.incident_audit_log	al
				join	Onyx6_0.dbo.users				u
						on	al.insert_by = u.[user_id]
				join	(	select	incident_id, insert_date = min(insert_date)
							from	Onyx6_0.dbo.incident_audit_log
							where	status_did = 104	--	Closed
							group by incident_id
						) al1	on	al.incident_id	= al1.incident_id
								and al.insert_date	= al1.insert_date
				left join	--	branch/department
						Onyx6_0.dbo.reference_parameter_ml	rp
						on	al.department_did	= rp.reference_parameter_did
						and	al.site_id			= rp.site_id
				where	al.status_did = 104				--	Closed
			)	ci	on	i.incident_id = ci.incident_id
		left join	--	current branch/department
				Onyx6_0.dbo.reference_parameter_ml	rp1	
				on	i.department_did	= rp1.reference_parameter_did
				and	i.site_id			= rp1.site_id
		left join	--	status
				Onyx6_0.dbo.reference_parameter_ml	rp2
				on	i.status_did	= rp2.reference_parameter_did
				and	i.site_id		= rp2.site_id
		left join	--	resolution code
				Onyx6_0.dbo.reference_parameter_ml	rp3
				on	i.resolution_did1	= rp3.reference_parameter_did
				and	i.site_id			= rp3.site_id
		where	i.incident_category_did	= 3		--	sales incidents
		and 	i.delete_status			= 0		--	not deleted
		and		i.desc1					like @Description + '%'
		and		i.update_date			between @StartDate
											and @EndDate
	)	a
where	(a.group_code		= @GroupId		or @GroupId		is null)
and		(a.assigned_to		= @AssignedTo	or @AssignedTo	is null)
and		(a.resolution_did1	= @ResCode		or @ResCode		is null)
and		(a.department_did	= @BranchId		or @BranchId	is null)
and		(a.status_did		= @StatusId		or @StatusId	is null);
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO