use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwimDetail_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessSwimDetail_v]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessSwimDetail_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/25/2007
Purpose  :	Consolidates the logic for creating the SWIM II file via BCP.  This
			view should be used by the file creation process after the "handler"
			has created actual transactions for the Process/Run.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
12/06/2007	Paul Hunter		Added CashBox override from the SWIM Detail table.
02/19/2008	Paul Hunter		Added Fund Type Code and Fund Type Detail Code from
							the SWIM Detail table.
07/22/2008	Paul Hunter		Added Items column to the "Record" value.
————————————————————————————————————————————————————————————————————————————————
*/

select	psd.RunId		--	for a specific run...
	,	psd.ProcessId	--	... of a given process
	,	psd.IsComplete	--	... that's isn't complete
	,	psd.ProcessSwimDetailId
	--	below are the columns used to export for the swim file
	,	Record	=	tcu.fn_ZeroPad(psd.AccountNumber, 17)
				+	isnull(psd.TransactionCd			, ps.TransactionCd)
				+	tcu.fn_ZeroPad(psd.Amount * 100, 10)
				+	tcu.fn_ZeroPad(psd.Items, 6)		--	NumberOfItems
				+	convert(char(8), psd.EffectiveOn, 112)
				+	isnull(psd.TransactionDescription	, ps.TransactionDescription)
				+	case ps.HasTraceNumber
					when 1 then cast(psd.TraceNumber as char(15))
					else space(15) end
				+	cast(isnull(psd.CashBox				, ps.CashBox) as char(10))
				+	space(4)							--	RetirementCd
				+	space(4)							--	RetirementYear
				+	isnull(psd.FundTypeCd				, ps.FundTypeCd)
				+	isnull(psd.FundTypeDetailCd			, ps.FundTypeDetailCd)
				+	isnull(psd.ClearingCategoryCd		, ps.ClearingCategoryCd)
				+	space(10)							--	CheckNumber
				+	space(4)							--	BalanceCategoryCd
				+	space(4)							--	BalanceTypeCd
				+	space(4)							--	ReversePaidInEffect
from	tcu.ProcessSwim			ps
join	tcu.ProcessSwimDetail	psd
		on	ps.ProcessId = psd.ProcessId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO