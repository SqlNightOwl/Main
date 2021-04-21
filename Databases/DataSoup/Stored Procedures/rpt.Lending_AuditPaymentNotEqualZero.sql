use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditPaymentNotEqualZero]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditPaymentNotEqualZero]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditPaymentNotEqualZero
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Payment Not Equal Zero' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;
		
select	a.OriginatingPerson	
	,	a.AcctNbr
	,	a.ContractDate	
	,	a.CurrMiAcctTypCd
	,	a.TotalPi
from	lnd.LoanQualityAudit		a
where	a.LoadOn			= @AuditDate
and		a.MjAcctTypCd		= 'CNS'
and		a.CurrAcctStatCD	= 'ACT'
and		a.CurrMIAcctTypCD	not in	('RLOC','PLOC')
order by a.OriginatingPerson;

--Audit Payment Not Equal Zero  (run every Sat night – look back 7 days)
--Select WH_AcctCOMMON.ORIGINATINGPersON, WH_AcctCOMMON.AcctNbr, WH_AcctCOMMON.CONTRACTDATE, 
--WH_AcctCOMMON.CURRMIAcctTYPCD
--, WH_AcctLOAN.TOTALPI 
--FROM WH_AcctCOMMON,WH_AcctLOAN,AcctLOAN 
--WHERE ((WH_AcctCOMMON.EFFDATE = ( Select MAX(EFFDATE) FROM WH_AcctCOMMON)) 
--AND (WH_AcctCOMMON.MJAcctTYPCD = 'CNS')
-- AND (WH_AcctCOMMON.CONTRACTDATE >= TO_DATE('09/01/2009','MM/DD/YYYY')) 
--AND (WH_AcctCOMMON.CONTRACTDATE <= TO_DATE('09/15/2009','MM/DD/YYYY')) 
--AND (WH_AcctCOMMON.CURRAcctSTATCD = 'ACT') 
--AND (UPPER(WH_AcctCOMMON.CURRMIAcctTYPCD) NOT IN ('RLOC','PLOC'))) 
--AND ((WH_AcctCOMMON.AcctNbr = AcctLOAN.AcctNbr)) 
--AND ((WH_AcctCOMMON.AcctNbr = WH_AcctLOAN.AcctNbr) AND (WH_AcctCOMMON.EFFDATE = WH_AcctLOAN.EFFDATE)) 
--ORDER BY 1
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO