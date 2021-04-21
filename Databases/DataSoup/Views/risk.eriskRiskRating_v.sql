use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskRiskRating_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[eriskRiskRating_v]
GO
setuser N'risk'
GO
CREATE view risk.eriskRiskRating_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/11/2008
Purpose  :	Mortgage view used for the ERisk application.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	r.MemberNumber
	,	r.LoanNumber
	,	r.FicsLoanNbr
	,	LoanBalance			= isnull(r.LoanBalance		, 0)
	,	SavingsBalance		= isnull(r.SavingsBalance	, 0)

	,	DelenquencyValue	= isnull(r.MaxDelenquency	, rr.DelinquentCoefficient)
	,	FICOValue			= fico.FICOScore * rr.FICOCoefficient
	,	LTV				= 0		--	from FICS
from	openquery(OSI, '
select	MemberNumber
	,	LoanNumber
	,	TaxId
	,	FicsLoanNbr
	,	decode(MaxDelenquency, null, 0, null) as MaxDelenquency
	,	LoanBalance
	,	SavingsBalance
from	erisk_RiskRating_vw')	r
left join
	(	select	l.TaxId
			,	l.FICOScore
		from	lnd.ExperianHistory	l
		join(	select	TaxId, ScoreOn = max(ScoreOn)
				from	lnd.ExperianHistory
				where	ScoreOn	> dateadd(year, -1, tcu.fn_FirstDayOfMonth(null))
				group by TaxId
			)	h	on	l.TaxId		= h.TaxId
					and	l.ScoreOn	= h.ScoreOn
	)	fico	on	r.TaxId = fico.TaxId
/*
left join
	(	select	Income			= 0		--	from FICS
			,	Debt			= 0		--	from FICS
			,	DebtValue		= .35 * r.Coefficient	--	(income/debt) * coefficient
		from	FICS.FICS.dbo.
		where	r.RiskRating = 'Debt'
	)
*/
cross join
	(	--	creates a single row result for the various values
		select	DebtCoefficient			= max(case RiskRating when 'Debt'		then Coefficient	else null end)
			,	DebtMaxValue			= max(case RiskRating when 'Debt'		then MaxValue		else null end)
			,	DelinquentCoefficient	= max(case RiskRating when 'Delinquent'	then Coefficient	else null end)
			,	DelinquentMaxValue		= max(case RiskRating when 'Delinquent'	then MaxValue		else null end)
			,	FICOCoefficient			= max(case RiskRating when 'FICO'		then Coefficient	else null end)
			,	FinalCoefficient		= max(case RiskRating when 'Final'		then Coefficient	else null end)
			,	LTVCoefficient			= max(case RiskRating when 'LTV'		then Coefficient	else null end)
			,	LTVMaxValue				= max(case RiskRating when 'LTV'		then MaxValue		else null end)
			,	SavingsCoefficient		= max(case RiskRating when 'Savings'	then Coefficient	else null end)
			,	SavingsMaxValue			= max(case RiskRating when 'Savings'	then MaxValue		else null end)
		from	risk.RiskRating
	)	rr
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO