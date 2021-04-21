use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial03Investor_vRaddon]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Colonial03Investor_vRaddon]
GO
setuser N'osi'
GO
CREATE view osi.Colonial03Investor_vRaddon
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/27/2007
Purpose  :	Used for generating the monthly Raddon file from Colonial Loans
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	MemberName			=	'"' + cast(ci.MortgagorFullName as char(30)) + '"'
	,	JointName			=	'"' + cast(ci.CoMortgagorFullName as char(30)) + '"'
	,	Address1			=	'"' + cast(ci.PropertyNumber + ci.PropertyStreetName as char(28)) + '"'
	,	Address2			=	null
	,	City				=	'"' + cast(ci.PropertyCity as char(28)) + '"'
	,	State				=	'"' + cast(ci.PropertyState as char(2)) + '"'
	,	Zip					=	ci.PropertyZip
	,	PrimaryPhone		=	null
	,	SSN					=	'"' + cast(cm.TaxID1 as char(9)) + '"'
	,	AcctNumber			=	'"' + cast(ci.ColonialLoanNum as char(6)) + '"'
	,	RecordType			=	'"M"'
	,	AcctType			=	'"' + cast(ci.CategoyNum as char(3)) + '"'
	,	LoanCollateralCode	=	null
	,	LoanPurposeCode		=	'"' + ci.LoanType + '"'
	,	AcctBalance			=	ci.PrincipalBalance
	,	InterestRate		=	cast(ci.InterestRate as decimal(6, 3))
 	,	DateOpened			=	'"' + left(ci.OriginalLoanDate, 2) 
							+	'/' + substring(ci.OriginalLoanDate, 3, 2)
							+	'/' + right(ci.OriginalLoanDate, 4) + '"'
 	,	MatureDate			=	'"' + left(ci.MaturityDate, 2) 
							+	'/' + substring(ci.MaturityDate, 3, 2)
							+	'/' + right(ci.MaturityDate, 4) + '"'
	,	Branch				=	'"032"'
	,	LoanOfficer			=	'"CMZZ"'
	,	OriginalBalance		=	cast(ci.OriginalLoanAmount as money)
	,	MemberNumber		=	'"' + cast(cm.MemberNumber as varchar(15)) + '"'
	,	LoanPaymentFreq		=	'"1"'
	,	DelinquencyFlag		=	case
								when datediff(day, cast(right(ci.DueDate, 4) + left(ci.DueDate, 4) as datetime), getdate()) > 30 then '"Y"'
								else '"N"' end
	,	PaymentAmount		=	cast(ci.TotalPaymentAmount as money)
 	,	NextPaymentDueDate	=	'"' + left(ci.DueDate, 2) 
							+	'/' + substring(ci.DueDate, 3, 2)
							+	'/' + right(ci.DueDate, 4) + '"'
	,	LoanTerm			=	ci.OriginalTerm
	,	SecondaryId			=	'"' + isnull(cm.TaxId2, '') + '"'
from	osi.Colonial03Investor	ci
join	osi.ColonialMember		cm
		on	ci.ColonialLoanNum	= cm.ColonialLoanNum
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO