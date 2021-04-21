use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Statement_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Statement_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.Statement_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/10/2008
Purpose  :	Wraps the osi.Statement table exposing only the Record column
			so that bulk copy can be performed using the OSI statement files.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/
select	Record
from	osi.Statement
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO