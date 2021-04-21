use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdEStatement_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[mdEStatement_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.mdEStatement_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/01/2008
Purpose  :	Wraps the osi.mdEStatement table exposing the Member Number column
			so that BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	MemberNumber
from	osi.mdEStatement
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO