use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditRlocCalcSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditRlocCalcSchedule]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditRlocCalcSchedule
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/03/2009
Purpose  :	Retrieves 'Audit RLOC Calculation Schedule' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;
		
select  a.OriginatingPerson
	,	a.AcctNbr
	,	a.NoteIntRate
	,	b.CalcSchedName
	,	a.CreditScore
	,	a.CreditLimitAmt
	,	a.ContractDate	
from	lnd.LoanQualityAudit	a
join	openquery(RPT2,'
		select	a.AcctNbr
			,	c.CalcSchedName
		from	Acct			a
		join	AcctSubAcct		s
				on	a.AcctNbr = s.AcctNbr
		left join
				MjMiAcctIntHist	t
				on	t.MjAcctTypCd   = a.MjAcctTypCd
				and	t.MiAcctTypCd	= a.CurrMiAcctTypCd
		left join
				AcctIntHist		i
				on	s.AcctNbr		= i.AcctNbr
				and	s.SubAcctNbr	= i.SubAcctNbr
		left join
				CalcSched		c
				on	nvl(i.CalcSchedNbr, t.CalcSchedNbr)	= c.CalcSchedNbr
		where   a.MjAcctTypCd   = ''CNS''
		and		s.BalCatCd		= ''NOTE''
		and		s.BalTypCd		= ''BAL''
		and		t.BalCatCd		= ''NOTE''
		and		t.BalTypCd		= ''BAL''
		and       (	i.EffDate	= (	select max(EffDate) from AcctIntHist
									where   AcctNbr		= i.AcctNbr
									and		SubAcctNbr	= i.SubAcctNbr
									and		InactiveDate is null)
				or	i.EffDate	is null    )'
		)	b	on a.AcctNbr = b.AcctNbr
where	a.LoadOn			= @AuditDate
and		a.MjAcctTypCd		= 'CNS'
and		a.CurrAcctStatCd	= 'ACT'
and		a.CurrMiAcctTypCd	= 'RLOC'
order by
		a.OriginatingPerson
	,	a.NoteIntRate;

----Audit RLOC Calculation Schedule (run every Sat night – look back 7 days)
--Select WH_AcctCOMMON.ORIGINATINGPersON, WH_AcctLOAN.AcctNbr, WH_AcctCOMMON.NOTEINTRATE, CALCSCHED.CALCSCHEDNAME
--, AcctLOAN.CREDITSCORE, WH_AcctLOAN.CREDITLIMITAMT, WH_AcctCOMMON.CONTRACTDATE 
--FROM WH_AcctCOMMON,WH_AcctLOAN,CALCSCHED,AcctLOAN 
--WHERE ((WH_AcctCOMMON.EFFDATE = ( Select MAX(EFFDATE) FROM WH_AcctCOMMON)) 
--AND (WH_AcctCOMMON.MJAcctTYPCD = 'CNS') 
--AND (UPPER(WH_AcctCOMMON.CURRMIAcctTYPCD) = 'RLOC') 
--AND (WH_AcctCOMMON.CONTRACTDATE >= TO_DATE('09/01/2009','MM/DD/YYYY')) 
--AND (WH_AcctCOMMON.CONTRACTDATE <= TO_DATE('09/15/2009','MM/DD/YYYY')) 
--AND (WH_AcctCOMMON.CURRAcctSTATCD = 'ACT')) 
--AND ((WH_AcctLOAN.AcctNbr = WH_AcctCOMMON.AcctNbr) AND (WH_AcctLOAN.EFFDATE = WH_AcctCOMMON.EFFDATE)) 
--AND ((WH_AcctCOMMON.NOTEINTCALCSCHEDNbr = CALCSCHED.CALCSCHEDNbr)) AND ((WH_AcctCOMMON.AcctNbr = AcctLOAN.AcctNbr))
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO