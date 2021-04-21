use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[RewardsNowLog_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[RewardsNowLog_v]
GO
setuser N'osi'
GO
CREATE view osi.RewardsNowLog_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	07/30/2007
Purpose  :	View to create file for RewardsNow using table rn_TransactionHistory
			along with Pers and  REWARDSNOW_CUSTOMER_VW from OSI
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/16/2008	Fijula Kuniyil	Changed the fields pulled from OSI to reflect schema 
							change in the OSI RewardsNow view
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	l.DDA
	,	l.Name1
	,	l.Address1
	,	l.Address2
	,	l.City
	,	l.State
	,	l.Zip
	,	l.Phone1
	,	l.CardNumber
	,	l.Status
	,	l.Trandate
	,	l.DDA			as DDA2
	,	l.TranCode
	,	l.TranAmt
	,	l.CardNumber	as AcctNum
from	osi.RewardsNowLog	l
join	openquery(OSI,'select DDA from texans.RewardsNow_Customer_vw')	o
		on	l.DDA	= o.DDA
where	l.EffDate	= (select max(EffDate) from osi.RewardsNowLog);	-- only data from prev month
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO