use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Notice_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Notice_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.Notice_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/01/2008
Purpose  :	Wraps the osi.ncrRemoteCaptureRaw table exposing only the columns 
			of the file so that BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Detail
from	osi.Notice
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO