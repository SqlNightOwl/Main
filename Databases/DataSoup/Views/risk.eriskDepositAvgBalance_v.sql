use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskDepositAvgBalance_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[eriskDepositAvgBalance_v]
GO
setuser N'risk'
GO
CREATE view risk.eriskDepositAvgBalance_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	02/14/2008
Purpose  :	Deposit average balance view used for the ERisk application.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/21/2008	Vivian Liu		Add SnapShotDate as the return field.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/12/2009	Paul Hunter		Changed to use the new eRisk Account extract table.
————————————————————————————————————————————————————————————————————————————————
*/

select	CustomerCd
	,	avg(AccountBalance) as AverageBalance
	,	EffectiveDate
from	risk.eriskAccount
where	MajorTypeCd not in ('CML','CNS','MTG')
group by CustomerCd, EffectiveDate;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO