use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_IncidentCount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_IncidentCount]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_IncidentCount
	@StartDate	datetime
,	@EndDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/19/2005
Purpose  :	Collects and summariezes Call Center activity by Department and
			Agent for the specified time frame.
History:
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
12/22/2008	Paul Hunter		Convereted to ONYX 6.0 schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set	@EndDate = convert(varchar, dateadd(day, 1, @EndDate), 101);

select	tmp.Department
	,	tmp.AgentName
	,	ServiceRequest		= sum(tmp.ServiceRequest)
	,	ServiceTask			= sum(tmp.ServiceTask)
	,	SalesOpportunity	= sum(tmp.SalesOpportunity)
	,	SalesTask			= sum(tmp.SalesTask)
from (	select	Department			= rtrim(g.group_desc)
			,	AgentName			= rtrim(u.[user_name])
			,	ServiceRequest		= case i.incident_category_did	when  2	then 1 else 0 end
			,	ServiceTask			= case t.task_category_did		when 12	then 1 else 0 end
			,	SalesOpportunity	= case i.incident_category_did	when  3	then 1 else 0 end
			,	SalesTask			= case t.task_category_did		when 13	then 1 else 0 end
		from	Onyx6_0.dbo.incident	i
		join	Onyx6_0.dbo.users		u
				on	i.insert_by = u.[user_id]
				and	i.site_id	= u.site_id
		join	Onyx6_0.dbo.user_group_ml_view	g
				on	u.group_code	= g.group_code
				and	u.site_id		= g.site_id
		left join
				Onyx6_0.dbo.task		t
				on	i.incident_id	= t.owner_id
				and	i.site_id		= t.site_id
				and	6				= t.owner_type_enum
		where	i.insert_date				between	@StartDate
												and	@EndDate
		and		i.delete_status				= 0
		and		g.parent_user_group_code	= 'CallCenter'
	)	tmp
group by
		tmp.Department
	,	tmp.AgentName;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO