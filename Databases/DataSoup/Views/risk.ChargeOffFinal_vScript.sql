use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOffFinal_vScript]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[ChargeOffFinal_vScript]
GO
setuser N'risk'
GO
CREATE view risk.ChargeOffFinal_vScript
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	11/23/2009
Purpose  :	Used to produce the OSI update scripts for the Final Loan Charge Off
			routine.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/09/2010	Paul Hunter		Added update to AcctWrn table for CCD on the primary
							Charge Off Account.
							Added update to AcctLockOut and AcctWrn tables for
							CCD for Share Accounts related to the Charge Off Account.
————————————————————————————————————————————————————————————————————————————————
*/

select	AccountNumber
	,	LoadedOn
	,	10		as StatementLine
	,	'
update AcctLockOut set InactiveDate = trunc(sysdate), '
	+	'DateLastMaint = sysdate where AcctNbr = ' + cast(AccountNumber as varchar(22))
	+	' and LockOutFlagCd = ''CCD'' and InactiveDate is null;
update AcctWrn set InactiveDate = trunc(sysdate), '
	+	'DateLastMaint = sysdate where AcctNbr = ' + cast(AccountNumber as varchar(22))
	+	' and WrnFlagCd = ''CCD'' and InactiveDate is null;'
	+	case
		when MinorCd in ('BFC','CBA','CFC','CIA','CRW','HRCK') then '
insert into AcctLockOut values (' + cast(AccountNumber as varchar(22))
		+	', trunc(sysdate), ''LCK1'', null, null, sysdate);'
		else ''
		end		as Script
from	risk.ChargeOffFinal

union all

--	change the flag for any related savings account
select	distinct
		AccountNumber
	,	LoadedOn
	,	20		as StatementLine
	,	'update AcctLockOut set InactiveDate = trunc(sysdate), '
	+	'DateLastMaint = sysdate where AcctNbr = ' + cast(s.AcctNbr as varchar(22))
	+	' and LockOutFlagCd = ''CCD'' and InactiveDate is null;
update AcctWrn set InactiveDate = trunc(sysdate), '
	+	'DateLastMaint = sysdate where AcctNbr = ' + cast(s.AcctNbr as varchar(22))
	+	' and WrnFlagCd = ''CCD'' and InactiveDate is null;'	as Script
from	risk.ChargeOffFinal	f
join	OSI..OSIBANK.ACCT	c
		on	f.AccountNumber = c.AcctNbr
join	OSI..OSIBANK.ACCT	s
		on	isnull(c.TaxRptForPersNbr, 0) = isnull(s.TaxRptForPersNbr, 0)
		and	isnull(c.TaxRptForOrgNbr , 0) = isnull(s.TaxRptForOrgNbr , 0)
where	s.MjAcctTypCd	=	'SAV'
and		c.AcctNbr		!=	s.AcctNbr

union all

--	add the commit statement
select	max(AccountNumber)	+ 1	as ChargeOffAccount
	,	LoadedOn
	,	90						as StatementLine
	,	'commit;'				as Script
from	risk.ChargeOffFinal
group by LoadedOn;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO