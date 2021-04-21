use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetail_vPayeeSummary]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[IrsDetail_vPayeeSummary]
GO
setuser N'osi'
GO
CREATE view osi.IrsDetail_vPayeeSummary
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/17/2007
Purpose  :	Summarizes the "C" Payee Total record to exclude TCC Accounts and to
			re-state the record count and the 12 amount columns.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	d.IrsReportId
	,	RowId	=	max(d.RowId) + 1
	,	IsTCC	=	case d.AccountNumber when x.AccountNumber then 1 else 0 end

	,	Detail	=	'C'
				+	right(replicate('0', 8) + cast(count(1) as varchar(8)), 8)
				+	cast('' as char(6))
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount1 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount2 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount3 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount4 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount5 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount6 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount7 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount8 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.Amount9 as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.AmountA as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.AmountB as bigint)) as varchar(18)), 18)
				+	right(replicate('0', 18) + cast(sum(cast(d.AmountC as bigint)) as varchar(18)), 18)
				+	replicate('0', 36)
				+	cast('' as char(232))
				+	right(replicate('0', 8) + cast(max(d.RowId) + 1 as varchar(8)), 8)
				+	cast('' as char(241))
from	osi.IrsDetail		d
left join
		osi.IrsDetailTCC	x
		on	d.AccountNumber = x.AccountNumber
where	d.RowType = 'B'
group by
		d.IrsReportId
	,	case d.AccountNumber when x.AccountNumber then 1 else 0 end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO