use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncpCoupon_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[ncpCoupon_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.ncpCoupon_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/09/2008
Purpose  :	Wraps the osi.ncpCpupon table exposing only the columns 
			of the file so that a bulk copy can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record
from	osi.ncpCoupon
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO