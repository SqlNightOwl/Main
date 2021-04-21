use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[SingleServiceFeeCloseLog_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[SingleServiceFeeCloseLog_vLoad]
GO
setuser N'osi'
GO
create view osi.SingleServiceFeeCloseLog_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/23/2008
Purpose  :	Used to load the final account closing list for the Single Service
			Fee process.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	AccountNumber
from	osi.SingleServiceFeeCloseLog
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO