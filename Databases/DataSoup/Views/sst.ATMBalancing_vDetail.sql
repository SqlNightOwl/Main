use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancing_vDetail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[ATMBalancing_vDetail]
GO
setuser N'sst'
GO
CREATE view sst.ATMBalancing_vDetail
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/21/2009
Purpose  :	Abstract presentation of the loaded CNS TS10 report for use in the
			ATM Balancing process.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	d.ReportOn
	,	x.Terminal
	,	max(x.Withdrawal)				as Withdrawal
	,	max(x.Fee)						as Fee
	,	max(x.Withdrawal) - max(x.Fee)	as NetWithdrawal
	,	max(x.DepositSave)				as DepositSave
	,	max(x.DepositCheck)				as DepositCheck
	,	max(x.DepositCrCard)			as DepositCrCard
	,	max(x.DepositCrLine)			as DepositCrLine
	,	max(x.Deposit)					as Deposit
from(	--	collect the terminal
		select	d.Terminal
			,	case
				when d.RecordLength = 132
				 and d.Record like '%TERM%' then cast(substring(d.Record, 95, 19) as money)
				else 0 end		as Withdrawal
			,	case d.RecordLength
				when 119 then cast(substring(d.Record, 22, 16) as money)
				else 0 end		as Fee
			,	case
				when d.RecordLength = 132
				 and d.Record like '%TERM%' then cast(substring(d.Record, 114, 19) as money)
				else 0 end		as Deposit
			,	case
				when d.RecordLength = 132
				 and d.Record like '%CHECKING%' then cast(substring(d.Record, 114, 19) as money)
				else 0 end		as DepositCheck
			,	case
				when d.RecordLength = 132
				 and d.Record like '%SAVINGS%' then cast(substring(d.Record, 114, 19) as money)
				else 0 end		as DepositSave
			,	case
				when d.RecordLength = 132
				 and d.Record like '%CREDIT CA%' then cast(substring(d.Record, 114, 19) as money)
				else 0 end		as DepositCrCard
			,	case
				when d.RecordLength = 132
				 and d.Record like '%CREDIT LI%' then cast(substring(d.Record, 114, 19) as money)
				else 0 end		as DepositCrLine
		from(	--	collect	information necessary to produce the report
				select	a.Record
					,	a.RowId
					,	t.Terminal
					,	len(a.Record)	as RecordLength
				from	sst.ATMBalancing	a
				join(	--	get the first/last row for each page
						select	f.RowId - 1 as BeginId
							,	isnull((select	top 1 RowId - 2 from sst.ATMBalancing
										where	RowId > f.RowId
										and		charindex('PAGE ', Record) > 0	)
									,(	select max(RowId) from sst.ATMBalancing )
									)	as EndId
							,	cast(right(f.Record, 8) as smallint) as Page
						from	sst.ATMBalancing f
						where	charindex('PAGE ', f.Record) > 0
					)	p	on	a.RowId between	p.BeginId
											and p.EndId
				join(	--	get the terminal Id
						select	RowId, rtrim(substring(Record, 12, 8)) as Terminal
						from	sst.ATMBalancing
						where	Record like '0TERMINAL:%'
					)	t	on	t.RowId between	p.BeginId
											and	p.EndId
				join(	--	get the page with the data 
						select	RowId from sst.ATMBalancing
						where	Record like '0TERMINAL AMOUNTS BY CLIENT DATE%'
					)	x	on	x.RowId between	p.BeginId
											and	p.EndId
			)	d	--	get the detail total lines for the terminal...
		where	d.Record like '%TERM TOTALS%'
			or(	d.Record like '%SAVINGS%'	and d.RecordLength = 132)
			or(	d.Record like '%CHECKING%'	and d.RecordLength = 132)
			or(	d.Record like '%CREDIT LI%'	and d.RecordLength = 132)
			or(	d.Record like '%CREDIT CA%'	and d.RecordLength = 132)
	)	x		--	summary report extract
cross apply
	(	--	the the relevant report date...
		select	cast(substring(Record, charindex('FOR', Record) + 4, 255) as datetime) as ReportOn
		from	sst.ATMBalancing where	RowId = 3	)	d
group by x.Terminal, d.ReportOn;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO