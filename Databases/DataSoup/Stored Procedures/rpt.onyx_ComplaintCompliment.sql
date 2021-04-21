use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_ComplaintCompliment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_ComplaintCompliment]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_ComplaintCompliment
	@beginOn	datetime
,	@endOn		datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/30/2008
Purpose  :	Report on Complaints and Compliments to be handled by Member Response.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
12/22/2008	Paul Hunter		Changed to ONYX 6.0 schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

--	make sure the begin/end dates are provided
set	@beginOn	= isnull(@beginOn, convert(varchar, getdate(), 101));
set	@endOn		= dateadd(day, 1, isnull(@endOn, @beginOn));

--	collect the Incident details...
select	MemberNumber	=	c.member_number
	,	Member			=	c.customer
	,	MemberType		=	c.customer_type
	,	CommentType		=	case i.disposition_did
							when 101706 then 'Complaints'
							else 'Compliments' end
	,	iIncidentId		=	i.secondary_id
	,	dtInsertDate	=	convert(char(10), i.insert_date, 101) + ' ' +
							convert(char(5) , i.insert_date, 108)
	,	AgentName		=	rtrim(u.[user_name])
	,	IncidentType	=	t.parameter_desc
	,	Source			=	s.parameter_desc
	,	Product			=	ip.incident_product_desc
	,	MinorProduct	=	i.product_minor_desc
	,	Description		=	i.desc1 + isnull(i.desc1, '')
	,	NoteSeq			=	wnd.seq_num
	,	NotesEntered	=	'***  Entered By: ' + rtrim(ebu.[user_name])
						+	' on: ' + convert(varchar, wnd.insert_date, 101)
						+	' ' + convert(char(5), wnd.insert_date, 108) + '  ***'
	,	Notes			=	wnd.work_note
from	Onyx6_0.dbo.incident				i
join	Onyx6_0.cs.customer_v				c
		on	i.owner_id	= c.customer_id
		and	i.site_id	= 1
join	Onyx6_0.dbo.users					u
		on	i.insert_by = u.[user_id]
		and	i.site_id	= u.site_id
join	Onyx6_0.dbo.reference_parameter_ml	t	--	Incident Type
		on	i.incident_type_did	= t.reference_parameter_did
		and	i.site_id			= t.site_id
join	Onyx6_0.dbo.reference_parameter_ml	s	--	Incident Source
		on	i.source_did	= s.reference_parameter_did
		and	i.site_id		= s.site_id
left join
		Onyx6_0.dbo.incident_product_ml		ip
		on	i.incident_product_code		= ip.incident_product_code
		and	i.incident_category_did		= ip.incident_category_did
		and	i.site_id					= ip.site_id
left join
		Onyx6_0.dbo.work_note_header	wnh
		on	i.incident_id	= wnh.owner_id
		and	6				= wnh.owner_type_enum
		and	i.site_id		= wnh.site_id
left join
		Onyx6_0.dbo.work_note_detail	wnd
		on	wnh.work_note_header_id	= wnd.work_note_header_id
		and	wnh.site_id				= wnd.site_id
left join	Onyx6_0.dbo.users			ebu
		on	wnd.insert_by	= ebu.[user_id]
		and	wnd.site_id		= ebu.site_id

where	i.incident_category_did	=	2					--	service
and		i.disposition_did		in	(101706, 101707)	--	complaint/compliment
and		c.customer_type_did		=	101542				--	members
and 	i.insert_date			between	@beginOn
								and		@endOn
order by
		i.disposition_did
	,	i.owner_id
	,	i.secondary_id
	,	wnd.seq_num;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO