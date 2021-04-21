use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditDepProperty]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditDepProperty]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditDepProperty
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Dep Property' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;
		
select	a.OriginatingPerson		
	,	a.ContractDate	
	,	a.AcctNbr
	,	a.NoteBal
	,	b.AcctNbr	as CollateralAcctNbr
	,	b.HoldPct
from	lnd.LoanQualityAudit	a
left outer join	
		openquery(RPT2,'
		select	AcctNbr
			,	LoanAcctNbr
			,	HoldPct
		from	osibank.AcctClatAcct
		where	AcctNbr is null'
	)	b	on	a.AcctNbr = b.LoanAcctNbr
where	a.LoadOn			=	@AuditDate
and		a.CurrMiAcctTypCd	in	('RVSS','ROCD','RCCD')
and		a.CurrAcctStatCd	=	'ACT';
    
----Audit Dep Property  (run every Sat night)
--Select WH_AcctCOMMON.ORIGINATINGPersON, WH_AcctCOMMON.CONTRACTDATE, WH_AcctCOMMON.AcctNbr, WH_AcctCOMMON.NOTEBAL
--, AcctCLATAcct.AcctNbr, AcctCLATAcct.HOLDPCT 
--FROM WH_AcctCOMMON,AcctCLATAcct 
--WHERE ((WH_AcctCOMMON.EFFDATE = ( Select MAX(EFFDATE) FROM WH_AcctCOMMON)) 
--AND (UPPER(WH_AcctCOMMON.CURRMIAcctTYPCD) IN ('RVSS','ROCD','RCCD')) 
--AND (UPPER(WH_AcctCOMMON.CURRAcctSTATCD) = 'ACT') AND (AcctCLATAcct.AcctNbr IS NULL ) 
--AND (WH_AcctCOMMON.CONTRACTDATE >= TO_DATE('03-01-2009','MM-DD-YYYY'))) 
--AND ((WH_AcctCOMMON.AcctNbr = AcctCLATAcct.LOANAcctNbr(+)))
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO