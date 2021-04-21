use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[AccountAudit_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [audit].[AccountAudit_v]
GO
setuser N'audit'
GO
CREATE view audit.AccountAudit_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/10/2008
Purpose  :	View to return a list of accounts for the Auditors.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	AcctNbr
	,	MjAcctTypCd					as MajorType
	,	CurrMiAcctTypCd				as MinorType
	,	CurrAcctStatCd				as AcctStatus
	,	TaxId
	,	TaxIdType
	,	EffDate
	,	cast(EffBalance as money)	as EffBalance
from	openquery(OSI, '
		select	a.AcctNbr
			,	a.MjAcctTypCd
			,	a.CurrMiAcctTypCd
			,	a.CurrAcctStatCd
			,	cast(nvl(p.TaxId, o.TaxId) as char(9))	as TaxId
			,	nvl(o.TaxIdTypCd, ''SSAN'')				as TaxIdType
			,	to_char(d.EffDate, ''mm/dd/yyyy'')		as EffDate
			,	osiBank.pack_Acct.func_Acct_Bal(a.AcctNbr, ''NOTE'', ''BAL'', d.EffDate) as EffBalance
		from(	select	texans.pkg_Date.LastDay_Months(-1) EffDate
				from	dual	)		d
			,	osiBank.Acct			a
		left outer join
				osiBank.ViewPersTaxId	p
				on	a.TaxRptForPersNbr = p.PersNbr
		left outer join
				osiBank.ViewOrgTaxId	o
				on	a.TaxRptForOrgNbr = o.OrgNbr');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO