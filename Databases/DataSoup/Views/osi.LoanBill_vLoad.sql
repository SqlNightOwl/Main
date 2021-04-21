use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[LoanBill_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[LoanBill_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.LoanBill_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/16/2008
Purpose  :	Wraps the LoanBill table exposing only the columns of the file so that 
			BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Detail
from	osi.LoanBill
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO