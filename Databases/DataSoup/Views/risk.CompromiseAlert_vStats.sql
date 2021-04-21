use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseAlert_vStats]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[CompromiseAlert_vStats]
GO
setuser N'risk'
GO
create view risk.CompromiseAlert_vStats
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/22/2009
Purpose  :	Retrieves the current stats for a given Alert.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	a.CompromiseId
	,	a.AlertId
	,	isnull(count(c.CNSStatus), 0)		as CNSReports
	,	isnull(sum(c.HasFraud), 0)			as HasFraud
	,	isnull(sum(c.IsReissued), 0)		as IsReissued
	,	isnull(sum(c.CardsReissued), 0)		as CardsReissued
	,	isnull(sum(c.AmountReported), 0)	as AmountReported
	,	isnull(sum(c.AmountRecovered), 0)	as AmountRecovered
	,	isnull(sum(c.AmountReported), 0)
	-	isnull(sum(c.AmountRecovered), 0)	as AmountLost
from	risk.CompromiseAlert	a
left join
		risk.CompromiseCard		c
		on	a.AlertId = c.AlertId
group by a.CompromiseId, a.AlertId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO