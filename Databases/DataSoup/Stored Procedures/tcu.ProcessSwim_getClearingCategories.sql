use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwim_getClearingCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSwim_getClearingCategories]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessSwim_getClearingCategories
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/22/2007
Purpose  :	Returns a list of available Clearing Categories for SWIM Processing.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	ClearCatCd
	,	ClearCatDesc
from	openquery(OSI, '
		select	ClearCatCd
			,	ClearCatDesc
		from	osiBank.ClearCat')
order by ClearCatDesc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO