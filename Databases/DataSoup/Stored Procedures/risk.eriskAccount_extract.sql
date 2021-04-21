use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskAccount_extract]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[eriskAccount_extract]
GO
setuser N'risk'
GO
create procedure risk.eriskAccount_extract
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/14/2009
Purpose  :	Extracts the OSI Account information used for Risk Rating assessment
			and eRisk file export.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

truncate table risk.eriskAccount;

insert	risk.eriskAccount
	(	AcctNbr
	,	CustomerCd
	,	MajorTypeCd
	,	MinorTypeCd
	,	StatusCd
	,	BranchOrgNbr
	,	OpeningBalance
	,	AccountBalance
	,	AverageBalance
	,	EscrowBalance
	,	UnappliedBalance
	,	CreditLimit
	,	InterestRate
	,	MaturityDate
	,	ContractDate
	,	CloseDate
	,	CountryCd
	,	ZipCd
	,	StateCd
	,	RevolverCd
	,	RiskRatingCd
	,	LoanQualityCd
	,	CreditScore
	,	PastDueAmount
	,	PastDueMonths
	,	LoanLossCd
	,	PurposeCd
	,	AmortizationTerm
	,	MaxDelenquency
	,	TaxId
	,	TexansPct
	,	NaicsCd
	,	RenewalCd
	,	FicsLoanNbr
	,	EffectiveDate
	)
select	AcctNbr
	,	CustomerCd
	,	MajorTypeCd
	,	MinorTypeCd
	,	StatusCd
	,	BranchOrgNbr
	,	OpeningBalance
	,	AccountBalance
	,	AverageBalance
	,	EscrowBalance
	,	UnappliedBalance
	,	CreditLimit
	,	InterestRate
	,	MaturityDate
	,	ContractDate
	,	CloseDate
	,	CountryCd
	,	ZipCd
	,	StateCd
	,	RevolverCd
	,	RiskRatingCd
	,	LoanQualityCd
	,	CreditScore
	,	PastDueAmount
	,	PastDueMonths
	,	LoanLossCatCd
	,	PurposeCd
	,	AmortTerm
	,	MaxDelenquency
	,	TaxId
	,	TexansPct
	,	NaicsCd
	,	RenewalCd
	,	FicsLoanNbr
	,	EffectiveDate
from	openquery(RPT2, '
select	AcctNbr
	,	CustomerCd
	,	MajorTypeCd
	,	MinorTypeCd
	,	StatusCd
	,	BranchOrgNbr
	,	OpeningBalance
	,	AccountBalance
	,	AverageBalance
	,	EscrowBalance
	,	UnappliedBalance
	,	CreditLimit
	,	InterestRate
	,	MaturityDate
	,	ContractDate
	,	CloseDate
	,	CountryCd
	,	ZipCd
	,	StateCd
	,	RevolverCd
	,	RiskRatingCd
	,	LoanQualityCd
	,	CreditScore
	,	PastDueAmount
	,	PastDueMonths
	,	LoanLossCatCd
	,	PurposeCd
	,	AmortTerm
	,	MaxDelenquency
	,	TaxId
	,	TexansPct
	,	NaicsCd
	,	RenewalCd
	,	FicsLoanNbr
	,	EffectiveDate
from	erisk_Account_vw');


alter index all on risk.eriskAccount rebuild;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO