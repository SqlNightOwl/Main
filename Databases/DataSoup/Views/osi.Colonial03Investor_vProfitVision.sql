use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial03Investor_vProfitVision]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Colonial03Investor_vProfitVision]
GO
setuser N'osi'
GO
CREATE view osi.Colonial03Investor_vProfitVision
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/27/2007
Purpose  :	Used for generating the monthly FR file for ProfitVision from the
			Colonial Loans
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select 	RecordType					= '"FR"'
	,	AccountCategory				= '"' + ci.CategoyNum + '"'
	,	DepartmentCode				= '"052"'
	,	Payment						= '"' + cast(ci.TotalPaymentAmount as varchar) + '"'
	,	CurrentBalance				= '"' + cast(ci.PrincipalBalance as varchar) + '"'
	,	CurrentRate					= '"' + cast(cast(ci.InterestRate as decimal(6, 3)) as varchar) + '"'
	,	MaturityDate				= ci.MaturityDate
	,	AmortizationDate			= '""'
	,	NextPaymentDate				= '"' + ci.DueDate + '"'
	,	PaymentFrequency			= '"1"'
	,	MaturityMethod				= '"2"'
	,	OriginationDate				= '"' + ci.OriginalLoanDate + '"'
	,	AccountId					= '"' + isnull(cast(nullif(cm.MemberNumber, 0) as varchar), '888888888888') + ci.ColonialLoanNum + '"'
	,	DelinquentFlag				= case when ci.PastDueAmount > 0 then '"Y"' else '"N"' end
	,	AverageBalance				= '"' + cast(ci.PrincipalBalance as varchar) + '"'
	,	Fees						= '""'
	,	OfficerCode					= '"CMZZ"'
	,	CustomerIdNumber			= '"' + isnull(cast(nullif(cm.MemberNumber, 0) as varchar(15)), '888888888888') + '"'
	,	ProcessThroughDate 			= '""'
	,	CustomerRiskCode 			= '""'
	,	CollateralRiskCode			= '""'
	,	InterestIncomeExpenseAmount	= '""'
	,	CurrencyCode				= '"' + cast(ci.OriginalTerm as varchar) + '"'
	,	TransferPriceAmount			= '""'
	,	OriginalPrincipalBalance	= '"' + cast(ci.OriginalLoanAmount as varchar) + '"'
	,	StatusCode					= '""'
	,	ParticipationType			= '""'
	,	AccountType					= '"L"'
	,	ParticipationNumber 		= '""'
from 	osi.Colonial03Investor	ci
join	osi.ColonialMember		cm
		on	ci.ColonialLoanNum = cm.ColonialLoanNum
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO