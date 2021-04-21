use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[Alert_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [ihb].[Alert_vLoad]
GO
setuser N'ihb'
GO
CREATE view ihb.Alert_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/17/2008
Purpose  :	Wraps the ihb_Alert table exposing only the Record column so that 
			BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record
from	ihb.Alert;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO