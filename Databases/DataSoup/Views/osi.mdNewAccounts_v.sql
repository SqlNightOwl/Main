use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdNewAccounts_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[mdNewAccounts_v]
GO
setuser N'osi'
GO
CREATE view osi.mdNewAccounts_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/07/2008
Purpose  :	Used to Exports new accounts for MicroDynamics.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	Value
from	openquery(OSI, 'select Value from texans.MicroDynamics_SSI_vw');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO