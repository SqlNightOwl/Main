use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[RewardsNowLog_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[RewardsNowLog_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.RewardsNowLog_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/16/2008
Purpose  :	Used to bulk load the TexansRewards files recieved from FiServ EFT.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	DDA
	,	Name1
	,	Address1
	,	Address2
	,	City
	,	State
	,	Zip
	,	Phone1
	,	CardNumber
	,	Status
	,	TranDate
	,	AccountNumber
	,	TranCode
	,	TranAmt
	,	ReversalTypCd
	,	Flag
from	osi.RewardsNowLog
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO