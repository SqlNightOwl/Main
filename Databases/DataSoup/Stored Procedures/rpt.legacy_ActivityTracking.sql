use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[legacy_ActivityTracking]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[legacy_ActivityTracking]
GO
setuser N'rpt'
GO
CREATE procedure rpt.legacy_ActivityTracking
	@MemberNumber	bigint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/30/2005
Purpose  :	Retrieves ActivityTracking information so that the ActivityTracking
			applicaiton can be retired.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/22/2008	Vivian Liu		Retrieve member record from the Enterprise database 
							PremierMember table instead of tcuDataSoup Member.
06/17/2008	Paul Hunter		Moved to SQL 2005.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set	@MemberNumber = isnull(@MemberNumber, 0);

select	m.MemberNumber
	,	MemberName			= rm.[Name]
	,	rm.CallStart
	,	rm.DispositionDate
	,	[Description]		= rm.Description2
	,	Product				= p.ProductName
	,	Employee			= e.[Name]
from	Legacy.ep.PremierMember	m
join	Legacy.ep.RequestMaster	rm
		on	m.MemberID		= rm.MemberID
left join
		Legacy.ep.Product		p
		on	rm.ProductID	= p.ProductID
left join
		Legacy.ep.Employee		e
		on	rm.EmployeeID	= e.EmployeeID
where	m.MemberNumber = @MemberNumber
order by
		rm.CallStart		desc
	,	rm.RequestMasterID	desc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO