use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowPayoff_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[EscrowPayoff_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.EscrowPayoff_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/01/2008
Purpose  :	Wraps the osi.EscrowPayoff table exposing only the Record column
			so that bulk copy can be performed using the OSI files.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record
from	osi.EscrowPayoff;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO