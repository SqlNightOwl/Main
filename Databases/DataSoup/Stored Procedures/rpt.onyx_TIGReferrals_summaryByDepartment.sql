use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_TIGReferrals_summaryByDepartment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_TIGReferrals_summaryByDepartment]
GO
setuser N'rpt'
GO
create procedure rpt.onyx_TIGReferrals_summaryByDepartment
	@begin_on		datetime	= null
,	@end_on			datetime	= null
,	@department_did	int			= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/17/2009
Purpose  :	Retruns TIG Referral statistics for the subject date range and/or 
			department.
			* If the dates passed are null then the current year is returned.
			* If the department is null then all departments are returned.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@product_code	nchar(20)
,	@res_win		int
,	@stat_closed	int
,	@stat_pending	int
,	@stat_referred	int

declare	@results	table
	(	department_did	int			not null
	,	referred		int			not null
	,	quoted			int			not null
	,	bound			int			not null
	,	status_date		datetime	not null
	,	row				int			identity primary key
	);

--	initialize the status/resolution values
select	@product_code	= 'TIG_INS'
	,	@res_win		= 102770
	,	@stat_closed	= 104
	,	@stat_pending	= 131
	,	@stat_referred	= 101512;


exec ops.SSRSReportUsage_ins @@procid;

--	clean/groom the parameters
set @begin_on		= convert(char(10), isnull(@begin_on, tcu.fn_FirstDayOfMonth(null))	, 121);
set @end_on			= convert(char(10), isnull(@end_on	, tcu.fn_LastDayOfMonth(null))	, 121) + ' 23:59:59.998';
set	@department_did	= nullif(@department_did, 0);

--	collect incident matching the criteria...
insert	@results
select	r.department_did
	,	case r.status_did when @stat_referred	then 1 else 0 end
	,	case r.status_did when @stat_pending	then 1 else 0 end
	,	case r.status_did when @stat_closed		then 1 else 0 end
	,	min(r.status_date)
from(	select	i.department_did
			,	i.secondary_id
			,	i.status_did
			,	convert(char(7), i.update_date, 121) + '-01'	as status_date
		from	Onyx6_0.dbo.incident	i	with (nolock)
		where	i.incident_product_code	= @product_code
		and		i.serial_number			is not null
		and		i.update_date			between @begin_on and @end_on
		and	(	i.status_did			in (@stat_pending, @stat_referred)
			or(	i.status_did			= @stat_closed and
				i.resolution_did1		= @res_win
			  )
			)
	union all
		select	i.department_did
			,	i.status_did
			,	i.secondary_id
			,	convert(char(7), i.update_date, 121) + '-01'	as status_date
		from	Onyx6_0.dbo.incident_audit_log	i	with (nolock)
		where	i.incident_product_code	= @product_code
		and		i.serial_number			is not null
		and		i.update_date			between @begin_on and @end_on
		and	(	i.status_did			in (@stat_pending, @stat_referred)
			or(	i.status_did			= @stat_closed and
				i.resolution_did1		= @res_win
			  )
			)
	)	r
group by
		r.secondary_id
	,	r.department_did
	,	r.status_did

--	return the final dataset
select	case left(d.parameter_desc, 1)
		when 'B' then 'Branches'
		else 'Departments' end				as department_type
	,	substring(d.parameter_desc, 4, 50)	as department
	,	sum(r.referred)						as referred
	,	sum(r.quoted)						as quoted
	,	sum(r.bound)						as bound
	,	datename(month, r.status_date)		as status_month
	,	year(r.status_date)					as status_year
from	@results				r
join	Onyx6_0.dbo.reference_parameter_ml	d
		on	r.department_did = d.reference_parameter_did
where	r.department_did = @department_did
	or	@department_did	 is null
group by
		d.parameter_desc
	,	r.status_date
order by
		d.parameter_desc
	,	r.status_date;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO