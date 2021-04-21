use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskRetailLending_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[eriskRetailLending_v]
GO
setuser N'risk'
GO
CREATE view risk.eriskRetailLending_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	02/14/2008
Purpose  :	RetailLending view used for the ERisk application.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/03/2008	Vivian Liu		Add outer join to retrieve the most current FICO and
							MDS Scores from the ExperianHistory table.
03/21/2008	Vivian Liu		Add SnapShotDate as the return field.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/12/2009	Paul Hunter		Changed to use the new eRisk Account extract table.
————————————————————————————————————————————————————————————————————————————————
*/

select	a.CustomerCd
	,	a.MinorTypeCd		as ProductType
	,	a.AcctNbr			as LoanNbr
	,	a.RiskRatingCd
	,	a.LoanQualityCd
	,	a.AccountBalance	as NoteBalance
	,	a.CreditLimit		as LoanAmount
	,	a.MaturityDate
	,	a.InterestRate
	,	a.StatusCd
	,	a.ContractDate		as DateOfNote
	,	'Retail'			as BusinessUnit
	,	a.RevolverCd
	,	a.CreditScore
	,	a.MaxDelenquency
	,	a.PastDueMonths
	,	a.PastDueAmount
	,	f.FICOScore
	,	f.MDSScore
	,	f.ScoreOn
	,	a.EffectiveDate
from	risk.eriskAccount	a
left join
	(	--	retrieve the most current FICO and MDS Scores
		select	h.TaxId
			,	convert(char(8), h.ScoreOn, 112) as ScoreOn
			,	h.FICOScore
			,	h.MDSScore
		from	lnd.ExperianHistory h
		join(	select	TaxId
					,	MaxScoreOn = max(ScoreOn)
				from	lnd.ExperianHistory
				group by TaxId
			)	s	on	h.TaxId		= s.TaxId
					and	h.ScoreOn	= s.MaxScoreOn
	)	f	on	a.TaxId = f.TaxId
where	a.MajorTypeCd = 'CNS';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO