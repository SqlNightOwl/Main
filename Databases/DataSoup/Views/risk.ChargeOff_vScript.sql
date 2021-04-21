use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOff_vScript]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[ChargeOff_vScript]
GO
setuser N'risk'
GO
CREATE view risk.ChargeOff_vScript
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	09/30/2009
Purpose  :	Used to produce the OSI update scripts for the Loan Charge Off routine.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

--	10) updates to the Charged Off account...
select	AccountNumber
	,	ShareAccount
	,	ChargeOffOn
	,	10	as StatementLine
	,	'
/*
**	NEW ACCOUNT
**	Charge Off	: ' + cast(AccountNumber	as varchar(22))	+ '
**	Membership	: ' + cast(ShareAccount		as varchar(22))	+ '
**	Major Type	: ' + MajorCd + '
**	ARFS Code	: ' + case ARFS when '' then 'none' else ARFS end + '
*/
	/*
	**	MODIFY CHARGED OFF ACCOUNT...
	*/
update	Acct set BranchOrgNbr = 2402, DateLastMaint = sysdate'
	+	case	--	if it's a loan without an ARFS code do nothing otherwise hold the mail...
		when AccountType = 'L' and len(ARFS) = 0 then ''
		else ', MailTypCd = ''HOLD'''
		end
	+	case AccountType	--	leave the status alone for all loans...
		when 'L' then ''
		else ', CurrAcctStatCd = ''IACT'''
		end
	+	' where AcctNbr = ' + ChargeOffAcct + ';'
		--	NEW SQL STATEMENT...
	+	'

	--	update/add the charged off account in the branch history table...
update	AcctBrOrgHist set InactiveDate = trunc(sysdate) where AcctNbr = '
	+	ChargeOffAcct + ' and InactiveDate is null and BrOrgNbr != 2402;

insert	into AcctBrOrgHist (AcctNbr, EffDate, BrOrgNbr, DateLastMaint, PostDate) 
	select ' + ChargeOffAcct + ', trunc(sysdate), 2402, sysdate, trunc(sysdate) from dual
	where not exists (select AcctNbr from AcctBrOrgHist where AcctNbr = ' + ChargeOffAcct
	+	' and BrOrgNbr = 2402 and InactiveDate is null);'
		--	NEW SQL STATEMENT...
	+	case AccountType
		when 'L' then ''
		else '

	--	change the charge off account to IACT in the history table for non-loan accounts...
insert	into AcctAcctStatHist (AcctNbr, EffDateTime, AcctStatCd, TimeUniqueExtn, DateLastMaint, PostDate) 
	select h.AcctNbr, sysdate, ''IACT'', t.TimeUniqueExtn, sysdate, trunc(sysdate)
	from AcctAcctStatHist h, ( select max(TimeUniqueExtn) + 1 as TimeUniqueExtn from AcctAcctStatHist ) t
	where not exists (select AcctNbr from AcctAcctStatHist where AcctStatCd = ''IACT'' and AcctNbr = '
	+	ChargeOffAcct + ') and h.AcctNbr = ' + ChargeOffAcct
	+	' and rownum = 1;'
		end
		--	change the CreditReportStatCd to 97 in AcctLoan talbe for all loans without * or **...
	+	case	
		when AccountType = 'L' and ARFS not like '*%'
		then '

	--	change the Loan CreditReportStatCd to 97...
update	AcctLoan set CreditReportStatCd = ''97'', DateLastMaint = sysdate where AcctNbr = '
	+	ChargeOffAcct + ';'
		else ''
		end
	+	case AccountType
		when 'D' then '

	--	change/add the account cycle to quarterly where not already quarterly...
update	AcctAcctCycleAppl set InactiveDate = trunc(sysdate), DateLastMaint = sysdate
	where AcctNbr = ' + ChargeOffAcct + ' and AcctCycleCd = ''EOM'' and ApplNbr = 360;

insert	into AcctAcctCycleAppl (AcctNbr, ApplNbr, EffDate, AcctCycleCd, DateLastMaint, ImageYN, TruncateYN, CycImmedChgYN) 
	select	a.AcctNbr, 360, trunc(sysdate), ''EOQ'', sysdate, ''Y'',''Y'',''Y''
	from	Acct a where a.AcctNbr = ' + ChargeOffAcct + '
	and not exists (select	AcctNbr	from AcctAcctCycleAppl
					where	AcctNbr		 = ' + ChargeOffAcct + '
					and		ApplNbr		 = 360 
					and		AcctCycleCd	 = ''EOQ'' 
					and		InactiveDate is null );'
		else ''
		end			as Script
from(	select	*, cast(AccountNumber as varchar(22)) as ChargeOffAcct
		from	risk.ChargeOff	) c

union all

--	20) updates to the Share Accounts Charged Off account
select	AccountNumber
	,	ShareAccount
	,	ChargeOffOn
	,	20	as StatementLine
	,	'
	/*
	**	MODIFY RELATED MEMBERSHIP SHARE ACCOUNT...
	*/
update	Acct set BranchOrgNbr = 2402, DateLastMaint = sysdate, MailTypCd = ''HOLD'', CurrAcctStatCd = ''IACT'''
	+	' where AcctNbr = ' + DepositAccount + ';'
	+	case MinorCd
		when '~SHS' then '

	--	update/add the BranchOrg in the history table
update	AcctBrOrgHist set InactiveDate = trunc(sysdate) where AcctNbr = '
	+	DepositAccount + ' and InactiveDate is null and BrOrgNbr != 2402;

insert	into AcctBrOrgHist (AcctNbr, EffDate, BrOrgNbr, DateLastMaint, PostDate) 
	select ' + DepositAccount + ', trunc(sysdate), 2402, sysdate, trunc(sysdate) from dual
	where not exists (select AcctNbr from AcctBrOrgHist where AcctNbr = ' + DepositAccount
	+	' and BrOrgNbr = 2402 and InactiveDate is null);

	--	change the share account to IACT in the history table [if not already done]
insert	into AcctAcctStatHist (AcctNbr, EffDateTime, AcctStatCd, TimeUniqueExtn, DateLastMaint, PostDate) 
	select h.AcctNbr, sysdate, ''IACT'', t.TimeUniqueExtn, sysdate, trunc(sysdate)
	from AcctAcctStatHist h, ( select max(TimeUniqueExtn) + 1 as TimeUniqueExtn from AcctAcctStatHist ) t
	where not exists (select AcctNbr from AcctAcctStatHist where AcctStatCd = ''IACT'' and AcctNbr = '
	+	DepositAccount + ') and h.AcctNbr = ' + DepositAccount
	+	' and rownum = 1;

	--	change/add the account cycle to quarterly where not already quarterly...
update	AcctAcctCycleAppl set InactiveDate = trunc(sysdate), DateLastMaint = sysdate
	where AcctNbr = ' + DepositAccount + ' and AcctCycleCd = ''EOM'' and ApplNbr = 360;

insert	into AcctAcctCycleAppl (AcctNbr, ApplNbr, EffDate, AcctCycleCd, DateLastMaint, ImageYN, TruncateYN, CycImmedChgYN) 
	select	a.AcctNbr, 360, trunc(sysdate), ''EOQ'', sysdate, ''Y'',''Y'',''Y''
	from	Acct a where a.AcctNbr = ' + DepositAccount + '
	and not exists (select	AcctNbr	from AcctAcctCycleAppl
					where	AcctNbr		 = ' + DepositAccount + '
					and		ApplNbr		 = 360 
					and		AcctCycleCd	 = ''EOQ'' 
					and		InactiveDate is null );'
		else ''
		end			as Script
from(	select	AccountNumber
			,	ShareAccount
			,	cast(AccountNumber as varchar(22)) as DepositAccount
			,	ChargeOffOn
			,	MinorCd
		from	risk.ChargeOff
		where	AccountType		=	'D'				--	deposit accounts
		and		AccountNumber	!=	ShareAccount	--	exculde when Charge Off = Membership account
		union
		select	AccountNumber
			,	ShareAccount
			,	cast(ShareAccount as varchar(22)) as DepositAccount
			,	ChargeOffOn
			,	'~SHS'	as MinorCd		--	made up minor similar to our member share
		from	risk.ChargeOff	
		where	ShareAccount > 0 )	c

union all

--	30)	add ACCO, MBPR & NOTE account warnings for loan accounts...
select	c.AccountNumber
	,	c.ShareAccount
	,	c.ChargeOffOn
	,	30 + t.Row		as StatementLine
	,	case row when 1 then '
	--	setup the loan account warning flags
'	else ''
	end
	+	'insert	into AcctWrn (AcctNbr, EffDate, WrnFlagCd, DateLastMaint) select '
	+	ChargeOffAcct + ', trunc(sysdate), ''' + t.Code + ''', sysdate from dual
	where not exists (select AcctNbr from AcctWrn where AcctNbr = '	+ ChargeOffAcct
	+	' and WrnFlagCd = ''' + t.Code + ''' and InactiveDate is null);'	as Script
from(	select	*, cast(AccountNumber as varchar(22)) as ChargeOffAcct
		from	risk.ChargeOff	) c
cross apply
	(	select	cast(value as char(4)) as Code, row
		from	tcu.fn_split('ACCO;MBPR;NOTE', ';') ) t
where	c.AccountType = 'L'	--	loans

union all

--	add ACCO, LCK3, MBPR & NOTE account warnings for checking accounts...
--	inactivate the PSMX flag for all checking accounts...
select	c.AccountNumber
	,	c.ShareAccount
	,	c.ChargeOffOn
	,	40 + t.row		as StatementLine
	,	case row when 1 then '
	--	setup the deposit account warning flags
'	else ''
	end
	+	case t.Code
		when 'PSMX' then  'update	AcctWrn set InactiveDate = trunc(sysdate), DateLastMaint = sysdate '
						+ 'where AcctNbr = ' + ChargeOffAcct + ' and WrnFlagCd = '''
						+ t.Code + ''' and InactiveDate is null;'
		else  'insert	into AcctWrn (AcctNbr, EffDate, WrnFlagCd, DateLastMaint) select ' 
		+	ChargeOffAcct + ', trunc(sysdate), ''' + t.Code + ''', sysdate from dual
		where not exists (select AcctNbr from AcctWrn where AcctNbr = ' + ChargeOffAcct
		+	' and WrnFlagCd = ''' + t.Code + ''' and InactiveDate is null);'
		end				as Script
from(	select	*, cast(AccountNumber as varchar(22)) as ChargeOffAcct
		from	risk.ChargeOff	) c
cross apply
	(	select	cast(value as char(4)) as Code, row
		from	tcu.fn_split('ACCO;LCK3;MBPR;NOTE;PSMX', ';') ) t
where	AccountType = 'D'	--	deposit

union all

--	add LCK1, LCK3 & MBPR account warning for checking & savings related accounts...
select	c.AccountNumber
	,	c.ShareAccount
	,	ChargeOffOn
	,	50 + t.row		as StatementLine
	,	'insert	into AcctWrn (AcctNbr, EffDate, WrnFlagCd, DateLastMaint) select '
	+	ChangeAccount + ', trunc(sysdate), ''' + t.Code + ''', sysdate from dual
	where not exists (select AcctNbr from AcctWrn where AcctNbr = ' + ChangeAccount
	+	' and WrnFlagCd = ''' + t.Code + ''' and InactiveDate is null);'	as Script
from(	select	AccountNumber
			,	ShareAccount
			,	ChargeOffOn
			,	cast(AccountNumber as varchar(22))	as ChangeAccount
		from	risk.ChargeOff
		where	MajorCd			= 'SAV'
		and		MinorCd			in('BSHS','CSHS','SPSA')	--	membership shares
		union
		select	ShareAccount						--	membership shares
			,	ShareAccount
			,	ChargeOffOn
			,	cast(ShareAccount as varchar(22))	as ChangeAccount
		from	risk.ChargeOff	
		where	ShareAccount > 0
		and		AccountNumber	!= ShareAccount ) c
cross join
	(	select	cast(value as char(4)) as Code, row
		from	tcu.fn_split('LCK1;LCK3;MBPR', ';') ) t

union all

--	add person warning flags ACCO, LCK1, MBPR & NOT1 for the owner...
select	distinct
		c.AccountNumber
	,	c.ShareAccount
	,	c.ChargeOffOn
	,	60 + t.row		as StatementLine
	,	case t.row
		when 1 then '
	--	setup the person warning flags
'
		else ''
		end
	+	'insert	into PersWrn (PersNbr, EffDate, WrnFlagCd, DateLastMaint) select '
	+	TaxOwner + ', trunc(sysdate), ''' + t.Code + ''', sysdate from dual
	where not exists (select PersNbr from PersWrn where PersNbr = ' + TaxOwner
	+	' and WrnFlagCd = ''' + t.Code + ''' and InactiveDate is null);'	as Script
from(	select	*, cast(OwnerNumber as varchar(22)) as TaxOwner
		from	risk.ChargeOff
		where	OwnerCd		= 'P'
		and		OwnerNumber	> 0	) c
cross apply
	(	select	cast(value as char(4)) as Code, row
		from	tcu.fn_split('ACCO;LCK1;MBPR;NOT1', ';') ) t

union all

--	add person warning flags ACCO, LCK1, MBPR & NOT1 for joint owners people...
select	distinct
		c.AccountNumber
	,	c.ShareAccount
	,	c.ChargeOffOn
	,	70 + t.row		as StatementLine
	,	case t.row
		when 1 then '
	--	setup the joint person warning flags
'
		else ''
		end
	+	'insert	into PersWrn (PersNbr, EffDate, WrnFlagCd, DateLastMaint) select '
	+	 JointOwner + ', trunc(sysdate), ''' + t.Code + ''', sysdate from dual
	where not exists (select PersNbr from PersWrn where PersNbr = ' + JointOwner
	+	' and WrnFlagCd = ''' + t.Code + ''' and InactiveDate is null);'	as Script
from(	select	c.AccountNumber
			,	c.ShareAccount
			,	c.ChargeOffOn
			,	cast(o.JointOwner as varchar(22)) as JointOwner
		from	risk.ChargeOff				c
		join	risk.ChargeOffJointOwner	o
			on	c.AccountNumber = o.AccountNumber	) c
cross apply
	(	select	cast(value as char(4)) as Code, row
		from	tcu.fn_split('ACCO;LCK1;MBPR;NOT1', ';') ) t

union all

--	add the commit statement
select	distinct
		max(AccountNumber)	+ 1	as ChargeOffAccount
	,	max(ShareAccount)	+ 1	as RelatedAccount
	,	max(ChargeOffOn)		as ChargeOffOn
	,	1000					as StatementLine
	,	'commit;'				as Script
from	risk.ChargeOff;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO