use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditLoanLimit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditLoanLimit]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditLoanLimit
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Loan Limit' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	AcctNbr
	,	OriginatingPerson
	,	ContractDate
	,	LoanLimitYN
	,	NoteBal
	,	CurrMiAcctTypCd
from	lnd.LoanQualityAudit
where	LoadOn			= @AuditDate
and		MjAcctTypCd		= 'CNS'
and		CurrMiAcctTypCd	not in ('RLOC','RPLC')
and		CurrAcctStatCd	= 'ACT'
and		LoanLimitYN		= 'Y';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO