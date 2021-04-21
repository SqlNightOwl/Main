use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditOESigners]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditOESigners]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditOESigners
	@AuditDate	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit OE Signers' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	a.OriginatingPerson
	,	a.ContractDate
	,	a.AcctNbr
	,	a.OwnerName
	,	a.CurrMiAcctTypCd
	,	a.TaxOwnerNbr	as	PersNbr
	,	b.Value
from	lnd.LoanQualityAudit	a
join	openquery(RPT2,'
		select	PersNbr
			,	Value
		from	PersUSERFIELD
		where	UserFieldCd = ''LLOE'''
	)	b	on	a.TaxOwnerNbr = b.PersNbr
where	LoadOn			= @AuditDate
and		CurrMiAcctTypCd	in	('ROAN','ROAU','RODR','ROST','RVSS','ROCD','ROCB','ROSG','RLOC')
--and		((UPPER(PersUSERFIELD.VALUE) < '2006-11-01') OR (PersUSERFIELD.VALUE IS NULL )))
and	(	b.Value < @AuditDate
	or	b.Value	is null )
order by b.Value;

--Select WH_AcctCOMMON.ORIGINATINGPersON, WH_AcctCOMMON.CONTRACTDATE, WH_AcctCOMMON.AcctNbr, 
--WH_AcctCOMMON.OWNERNAME
--, WH_AcctCOMMON.CURRMIAcctTYPCD, PersVIEW.PersNbr, PersUSERFIELD.VALUE 
--FROM WH_AcctCOMMON,PersVIEW,PersUSERFIELD 
--WHERE ((RTRIM(UPPER(PersUSERFIELD.USERFIELDCD)) LIKE '%LLOE%') A
--ND (WH_AcctCOMMON.CONTRACTDATE >= TO_DATE('04-23-2009','MM-DD-YYYY')) 
--AND (UPPER(WH_AcctCOMMON.CURRMIAcctTYPCD) IN ('ROAN','ROAU','RODR','ROST','RVSS','ROCD','ROCB','ROSG','RLOC')) 
--AND (WH_AcctCOMMON.EFFDATE = ( Select MAX(EFFDATE) FROM WH_AcctCOMMON)) 
--AND ((UPPER(PersUSERFIELD.VALUE) < '2006-11-01') OR (PersUSERFIELD.VALUE IS NULL ))) 
--AND ((WH_AcctCOMMON.TaxRptForPersNbr = PersVIEW.PersNbr)) AND ((PersVIEW.PersNbr = PersUSERFIELD.PersNbr)) 
--ORDER BY 7
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO