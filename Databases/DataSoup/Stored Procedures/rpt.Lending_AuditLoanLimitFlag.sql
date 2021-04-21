use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditLoanLimitFlag]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditLoanLimitFlag]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditLoanLimitFlag
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Loan Limit Flag Not Equal N' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;
		
select	a.OriginatingPerson	
	,	a.AcctNbr
	,	a.ContractDate	
	,	a.LoanLimitYN
	,	a.NoteBal
	,	a.CurrMiAcctTypCd
from	lnd.LoanQualityAudit							a
where	a.LoadOn				= @AuditDate
and		a.MjAcctTypCd		=	'CNS'
and		a.CurrAcctStatCd	=	'ACT'
and		a.CurrMIAcctTypCd	in	('RLOC','RPLC')
and		a.LoanLimitYN		=	'N';

----Audit Loan Limit Flag Not Equal N  (run every Sat night – look back 7 days)
--Select WH_AcctCOMMON.ORIGINATINGPersON, WH_AcctCOMMON.AcctNbr, WH_AcctCOMMON.CONTRACTDATE, AcctLOAN.LOANLIMITYN
--, WH_AcctCOMMON.NOTEBAL, WH_AcctCOMMON.CURRMIAcctTYPCD 
--FROM WH_AcctCOMMON,AcctLOAN 
--WHERE ((WH_AcctCOMMON.EFFDATE = ( Select MAX(EFFDATE) FROM WH_AcctCOMMON))
--AND (UPPER(WH_AcctCOMMON.MJAcctTYPCD) = 'CNS') 
--AND (WH_AcctCOMMON.CONTRACTDATE BETWEEN TO_DATE('09/01/2009','MM/DD/YYYY') AND TO_DATE('09/15/2009','MM/DD/YYYY')) 
--AND (UPPER(WH_AcctCOMMON.CURRAcctSTATCD) = 'ACT') AND 
--(UPPER(WH_AcctCOMMON.CURRMIAcctTYPCD) IN ('RLOC','RPLC')) AND (UPPER(AcctLOAN.LOANLIMITYN) = 'N')) 
--AND ((WH_AcctCOMMON.AcctNbr = AcctLOAN.AcctNbr))
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO