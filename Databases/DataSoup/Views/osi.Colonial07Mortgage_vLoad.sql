use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial07Mortgage_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Colonial07Mortgage_vLoad]
GO
setuser N'osi'
GO
CREATE view osi.Colonial07Mortgage_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/05/2008
Purpose  :	Wraps the osi.Colonial07Mortgage table exposing the columns for the
			file so that BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	DiskCode
	,	CompanyCode
	,	ColonialLoanNum
	,	LienType
	,	InvestorNum
	,	CategoyNum
	,	LoanNum
	,	PrincipalBalance
	,	OriginalTerm
	,	InterestRate
	,	OriginalLoanDate
	,	LoanType
	,	PIConstant
	,	OriginalLoanAmount
	,	AppraisedValue
	,	NextInterestChangeDate
	,	PIConstantChangeDate
	,	Filler_1
	,	InvestorNum2
	,	CategoryNum2
	,	Lien2LoanNum
	,	Lien2PrincipalBalance
	,	Lien2LoanTerm
	,	Lien2InterestRate
	,	Lien2OriginalLoanDate
	,	Lien2LoanType
	,	Lien2PIConstant
	,	Lien2OriginalLoanAmount
	,	Filler_2
	,	MortgagorShortName
	,	MortgagorInitials
	,	MortgagorFullName
	,	MortgagorTaxID
	,	CoMortgagorShortName
	,	CoMortgagorInitials
	,	CoMortgagorFullName
	,	CoMortgagorTaxID
	,	PropertyNumber
	,	PropertyDirection
	,	PropertyStreetName
	,	PropertyCity
	,	PropertyState
	,	PropertyZip
	,	InCareOfLine
	,	MailingAddress1
	,	MailingAddress2
	,	MailingCity
	,	MailingState
	,	MailingZip
	,	DueDate
	,	EscrowBalance
	,	EscrowAdvanceBalance
	,	TotalPaymentAmount
	,	MonthlyEscrowPaid
	,	BorrowerServiceCharge
	,	SubsidyBuydownAmount
	,	MaturityDate
	,	Filler_3
	,	AHLifePremiumAmount1
	,	CoverageType1
	,	AHLifePremiumAmount2
	,	CoverageType2
	,	AHLifePremiumAmount3
	,	CoverageType3
	,	AHLifePremiumAmount4
	,	CoverageType4
	,	LastPaymentPosted
	,	PastDueAmount
	,	LateChargeBalanceDue
	,	InspectionFeeBalanceDue
	,	NSFFeesDue
	,	AttorneyFeesDue
	,	BillMode
	,	DateLoanRemoved
	,	ColonialProductTypeCode
	,	MersMinNumber
	,	BallonDate
	,	YTDPrincipalPaid
	,	YTDInterestPaid
	,	YTDTaxesPaid
	,	YTDHazardInsurancePaid
	,	YTDFhaPmiPaid
	,	FirstPaymentDueDate
	,	Filer_4
	,	Lien2YTDPrincipalPaid
	,	Lien2YTDInterestPaid
	,	Lien2FirstPaymentDueDate
	,	Filler_5
	,	ProductCode
	,	ClassCode
	,	BranchCode
	,	GroupCode
	,	Filler_6
from	osi.Colonial07Mortgage;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO