use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[BusinessFee_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [ihb].[BusinessFee_vLoad]
GO
setuser N'ihb'
GO
CREATE view ihb.BusinessFee_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/06/2008
Purpose  :	Used by the Business Banking Fee process for bulk loading of monthly
			services for creating a business fee SWIM file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	AccountNumber
	,	Service
	,	Items
from	ihb.BusinessFee
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO