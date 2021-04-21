use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[lnd_ProductList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[lnd_ProductList]
GO
setuser N'rpt'
GO
CREATE procedure rpt.lnd_ProductList
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/18/2005
Purpose  :	Retrieves a list of Products from the Enterprise database.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

exec ops.SSRSReportUsage_ins @@procid

select	distinct
		Product		= null
	,	ProductName	= '<All Products>'

union

select	distinct
		Product		= ProductName
	,	ProductName
from	Legacy.ep.Product
where	DepartmentID	in (262, 263)
order by
		ProductName
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO