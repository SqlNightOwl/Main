use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditPaymentMethodFrequency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditPaymentMethodFrequency]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditPaymentMethodFrequency
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Payment Method Frequency' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;
		
select	distinct
		a.AcctNbr
	,	a.PmtMethCd
	,	a.Product
	,	a.OriginatingPerson	
	,	b.PmtCalPeriodCd
	,	a.ContractDate	
from	lnd.LoanQualityAudit	a
join	openquery(RPT2,'
		select  AcctNbr
			,	PmtCalPeriodCd
		from	AcctLoanPmtHist	
		where	PmtCalPeriodCd	!=	''MNTH'''
	)	b	on	a.AcctNbr	=	b.AcctNbr			
where	a.LoadOn			= @AuditDate
and		a.MjAcctTypCd		= 'CNS'
and		a.CurrAcctStatCD	= 'ACT'
and		a.PmtMethCd			= 'COUP'
order by a.AcctNbr
	,	a.Product;

----Audit Payment Method Frequency  (run every Sat night – look back 7 days)
--Select DISTINCT WH_AcctCOMMON.AcctNbr, WH_AcctLOAN.PMTMETHCD, WH_AcctCOMMON.PRODUCT, WH_AcctCOMMON.ORIGINATINGPersON
--, AcctLOANPMTHIST.PMTCALPERIODCD, WH_AcctCOMMON.CONTRACTDATE 
--FROM WH_AcctCOMMON,WH_AcctLOAN,AcctLOANPMTHIST 
--WHERE ((WH_AcctCOMMON.EFFDATE = ( Select MAX(EFFDATE) FROM WH_AcctCOMMON)) 
--AND (WH_AcctCOMMON.CONTRACTDATE >= TO_DATE('09/01/2009','MM/DD/YYYY')) 
--AND (WH_AcctCOMMON.CONTRACTDATE <= TO_DATE('09/30/2009','MM/DD/YYYY')) 
--AND (WH_AcctCOMMON.MJAcctTYPCD = 'CNS') AND (WH_AcctLOAN.PMTMETHCD = 'COUP') 
--AND (UPPER(AcctLOANPMTHIST.PMTCALPERIODCD) <> 'MNTH') AND (WH_AcctCOMMON.CURRAcctSTATCD = 'ACT')) 
--AND ((WH_AcctCOMMON.AcctNbr = WH_AcctLOAN.AcctNbr)) AND ((AcctLOANPMTHIST.AcctNbr = WH_AcctCOMMON.AcctNbr))
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO