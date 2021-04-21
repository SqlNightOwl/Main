use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetail_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[IrsDetail_v]
GO
setuser N'osi'
GO
CREATE view osi.IrsDetail_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/06/2007
Purpose  :	View indicates which accounts belong to TCC so they may be excluded.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
11/17/2008	Paul Hunter		Made into union query to include corrected C records.
————————————————————————————————————————————————————————————————————————————————
*/

select	d.RowId
	,	d.IrsReportId
	,	d.RowType
	,	d.AccountNumber
	,	d.Detail
	,	IsTCCAccount	= case d.AccountNumber when t.AccountNumber then 1 else 0 end
from	osi.IrsDetail		d
left join
		osi.IrsDetailTCC	t
		on	d.AccountNumber = t.AccountNumber
where	d.RowType != 'C'	--	exclude the Payee Summary records

union all

--	include the re-stated Payee Summary "C" records
select	RowId
	,	IrsReportId
	,	RowType			= 'C'
	,	AccountNumber	= 0
	,	Detail
	,	IsTCC
from	osi.IrsDetail_vPayeeSummary;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO