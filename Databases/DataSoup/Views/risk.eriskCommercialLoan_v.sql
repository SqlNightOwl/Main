use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskCommercialLoan_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[eriskCommercialLoan_v]
GO
setuser N'risk'
GO
CREATE view risk.eriskCommercialLoan_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	02/14/2008
Purpose  :	Commercial Loan view used for the ERisk application.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/21/2008	Vivian Liu		Add SnapShotDate as the return field and added the
							"LoanLossCatCd" and "BranchOrgNbr" from  OSI database.
04/10/2008	Paul Hunter		Changed the link to erisk_Raddon file to accomodate
							different load (bukl insert) process.
05/09/2008	Vivian Liu		Remove the query related to erisk_Raddon.
							Add the field to indicate the complete percentage of 
							"Texans Family Of Companies".
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/12/2009	Paul Hunter		Changed to use the new eRisk Account extract table.
————————————————————————————————————————————————————————————————————————————————
*/

select	CustomerCd
	,	AcctNbr			as LoanNumber
	,	'TCC'			as BusinessUnit
	,	MinorTypeCd		as ProductType
	,	NAICSCD
	,	CountryCd
	,	StateCd
	,	ZipCd
	,	RiskRatingCd
	,	LoanQualityCd
	,	PurposeCd
	,	AccountBalance	as NoteBalance
	,	OpeningBalance	as LoanAmount
	,	RevolverCd
	,	MaturityDate
	,	AmortizationTerm
	,	InterestRate
	,	StatusCd
	,	PastDueMonths
	,	PastDueAmount
	,	LoanLossCd
	,	BranchOrgNbr
	,	EffectiveDate
	,	TexansPct
from	risk.eriskAccount
where	MajorTypeCd = 'CML';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO