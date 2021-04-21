use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_MortgageReferrals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_MortgageReferrals]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_MortgageReferrals
	@StartDate	datetime
,	@EndDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	05/09/08
Purpose  :	Number of Mortgage Referrals made.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
12/22/2008	Paul Hunter		Converted to ONYX 6.0 schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set @EndDate = dateadd(millisecond, -1, dateadd(day, 1, @EndDate));

select	dtInsertDate	= i.insert_date
	,	ia2.ReferredDate
	,	IncidentId		= i.secondary_id
	,	MemberLastName	= p.last_name
	,	MemberFirstName	= p.first_name
	,	MemberNumber	= p.assigned_id
	,	ia2.StaffName
from	Onyx6_0.dbo.incident	i
join	Onyx6_0.dbo.individual	p
		on	i.owner_id	= p.individual_id
		and	i.site_id	= p.site_id
join	Onyx6_0.dbo.users		u1
		on	i.assigned_to	= u1.[user_id]
		and	N'RE_Loan'		= u1.group_code
		and	i.site_id		= u1.site_id
left join
	(	select	ia.incident_id
			,	StaffName		= rtrim(u.[user_name])
			,	ReferredDate	= ia1.update_date
		from	Onyx6_0.dbo.incident_audit_log	ia
		join	Onyx6_0.dbo.users				u
				on	ia.insert_by = u.[user_id]
		join(	select 	incident_id, update_date = min(update_date)
				from	Onyx6_0.dbo.incident_audit_log
				where	status_did = 101512
				group by incident_id
			)	ia1	on	ia.incident_id	= ia1.incident_id
					and	ia.update_date	= ia1.update_date
	)	ia2	on	ia2.incident_id = i.incident_id
where	i.incident_category_did	= 3
and		i.status_did			not in (104, 102560)
and		i.delete_status			= 0
and		i.insert_date			between @StartDate
									and @EndDate;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO