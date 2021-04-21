use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ihb_InactiveUsers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ihb_InactiveUsers]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ihb_InactiveUsers
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	05/13/2008
Purpose  :	Retrieve IHB Users and matches them to the OSI Account information
			for Users with closed Checking, Savings and/or Memberships.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/27/2008	Paul Hunter		Simplified/streamlined the routine. Added the period
							and date of the last login.
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@period		int
,	@periodName	varchar(50);

exec ops.SSRSReportUsage_ins @@procid;

--	collect the most recent period and convert it to its "name" value
select	@period		= Period
	,	@periodName	= datename(month, cast(Period as varchar) + '01' ) + ' '
					+ left(cast(Period as varchar), 4)
from(	select	Period = max(Period)
		from	DataSoup.ihb.ActiveUser
	)	p;

select	Period			= @periodName
	,	u.MemberNumber
	,	Member			= isnull(u.FirstName + ' ', '') + isnull(u.LastName, '')
	,	ClosedChecking	= case when o.OpenChecking	= 0 then 'Y' when o.OpenChecking is null then 'NC' else 'N' end
	,	ClosedSaving	= case when o.OpenSaving	= 0 then 'Y' when o.OpenSaving	is null then 'NS' else 'N' end
	,	ClosedMember	= case when o.OpenAccounts	= 0 then 'Y' else 'N' end
	,	LastLoginOn		= convert(char(10), u.LastSuccessfulLogin, 101)
from	DataSoup.ihb.ActiveUser	u
join	openquery(OSI, '
		select	MemberNumber
			,	OpenAccounts
			,	OpenChecking
			,	OpenSaving
		from	texans.ihb_User_vw'
	)	o	on	u.MemberNumber = o.MemberNumber
where	u.Period = @period
and	(	o.OpenChecking	= 0
	or	o.OpenSaving	= 0	)
order by u.LastName, u.FirstName;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO