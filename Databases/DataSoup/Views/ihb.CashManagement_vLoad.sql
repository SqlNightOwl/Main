use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[CashManagement_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [ihb].[CashManagement_vLoad]
GO
setuser N'ihb'
GO
CREATE view ihb.CashManagement_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/18/2008
Purpose  :	Wraps the ihb.CashManagement table exposing the Record column so that
			BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record
from	ihb.CashManagement
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO