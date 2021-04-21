use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[mgmt_OSIDeletedPersOrg]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[mgmt_OSIDeletedPersOrg]
GO
setuser N'rpt'
GO
CREATE procedure rpt.mgmt_OSIDeletedPersOrg
	@From	datetime
,	@To		datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/02/2008
Purpose  :	Displays deleted OSI person and org records between the from/to dates.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
12/22/2008	Paul Hunter		Changed to use ONYX 6.0 schema.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

select	CustomerType	= case o.CustomerType when 'PERS' then 'Person' else 'Organization' end
	,	CustomerNbr		
	,	DateLastMaint
	,	EffectiveOn
	,	Employee
	,	MemberNumber	= coalesce(c.assigned_id, 'Not found')
	,	MemberName		= coalesce(c.customer	, 'Not found')
from	openquery(OSI, '
		select	nvl(a.SubjPersNbr, a.SubjOrgNbr)	as CustomerNbr
			,	decode(	a.SubjOrgNbr
					,	null, ''PERS''
					,	''ORG''	)					as CustomerType
			,	a.DateLastMaint
			,	trunc(a.DateLastMaint)				as EffectiveOn
			,	pe.FirstName ||'' ''||
				pe.LastName							as Employee
		from	osiBank.Actv	a
		join	osiBank.Pers	pe
				on a.RespPersNbr	= pe.PersNbr
		left join 
				osiBank.Pers	p
				on	a.SubjPersNbr	= p.PersNbr
				and a.DateLastMaint	= p.DateLastMaint
		left join 
				osiBank.Org		o
				on	a.SubjOrgNbr	= o.OrgNbr
				and a.DateLastMaint	= o.DateLastMaint
		where (	p.PurgeYN = ''Y''
			or	o.PurgeYN = ''Y'' )
		and		a.ActvCatCd	in (''OMNT'', ''PMNT'')
		and		a.ActvTypCd	in (''ORG'', ''PERS'')'
	)	o
left join	Onyx6_0.cs.customer_v	c
		on	1				= c.site_id
		and	o.CustomerNbr	= c.osi_id
		and	o.CustomerType	= c.osi_type
where	o.EffectiveOn	between	convert(char(10), isnull(@from	, getdate()), 121)
						and		convert(char(10), isnull(@to	, getdate()), 121)
order by
		o.EffectiveOn
	,	o.CustomerType
	,	o.CustomerNbr;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO