use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancing_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[ATMBalancing_vLoad]
GO
setuser N'sst'
GO
CREATE view sst.ATMBalancing_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/19/2009
Purpose  :	Wraps the sst.ATMBalancing table exposing only the Record column so
			that BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Record
from	sst.ATMBalancing;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO