use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[FundsAvailability_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[FundsAvailability_v]
GO
setuser N'osi'
GO
CREATE view osi.FundsAvailability_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/03/2008
Purpose  :	Retrieves the Funds Availability schedule from OSI for Remote Capture.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	ClearCatCd
	,	ClearCatDesc
	,	case charindex('-Days', ClearCatDesc)
		when 0 then 0
		else cast(reverse(substring(reverse(ClearCatDesc), charindex('-', reverse(ClearCatDesc)) + 1, 2)) as int)
		end			as Availability
from	openquery(OSI, '
		select	ClearCatCd
			,	ClearCatDesc
		from	osiBank.ClearCat
		where	ClearCatCd like ''%MM''
			or	ClearCatCd = ''IMED''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO