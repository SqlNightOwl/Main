use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowAnalysis_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[EscrowAnalysis_vLoad]
GO
setuser N'osi'
GO
create view osi.EscrowAnalysis_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/04/2007
Purpose  :	Wraps the osi.EscrowAnalysis table exposing the Record column for the
			file so that BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record
from	osi.EscrowAnalysis
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO