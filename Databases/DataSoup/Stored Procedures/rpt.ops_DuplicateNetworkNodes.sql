use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ops_DuplicateNetworkNodes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ops_DuplicateNetworkNodes]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ops_DuplicateNetworkNodes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/24/2008
Purpose  :	Returns duplicate computers (network nodes) from OSI and displays
			where (Org Name) the computer is located.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

select	OrgName
	,	NtwkNodeName
	,	NbrMachines
	,	PhysAddr
	,	NtwkNodeTypCd
from	openquery(OSI, '
		select	n.NtwkNodeName
			,	cast(d.NbrMachines as int) as NbrMachines
			,	n.PhysAddr
			,	n.NtwkNodeTypCd
			,	o.OrgName
		from	osiBank.NtwkNode	n
		join	osiBank.Org			o
				on	n.LocOrgNbr	= o.OrgNbr
		join(	select	NtwkNodeName, count(1) as NbrMachines
				from	osiBank.NtwkNode
				where	NtwkNodeTypCd not in (''ATM'', ''LASR'')
				group by NtwkNodeName having count(1) > 1
			)	d	on	n.NtwkNodeName = d.NtwkNodeName')
order by
	OrgName
,	NtwkNodeName;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO