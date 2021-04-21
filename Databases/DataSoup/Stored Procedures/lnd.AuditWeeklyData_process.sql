use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[AuditWeeklyData_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[AuditWeeklyData_process]
GO
setuser N'lnd'
GO
CREATE procedure lnd.AuditWeeklyData_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	11/27/2009
Purpose  :	Loads lnd.AuditWeeklyData with information for Lending Audit Reports. 
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		varchar(50)
,	@detail		varchar(4000)
,	@loadOn		datetime
,	@retention	int
,	@result		int

--	initialize the variables...
select	@cmd		= ''
	,	@detail		= ''
	,	@loadOn		= convert(char(10), getdate(), 121)
	,	@retention	= cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Peeriod') as int) * -1
	,	@result		= 0;

if not exists (	select	top 1 LoadOn from lnd.LoanQualityAudit
				where	LoadOn = @loadOn	)
begin
	begin try
		set	@cmd = 'delete old data'
		delete	lnd.LoanQualityAudit
		where	LoadOn < dateadd(day, @retention, @loadOn);

		set	@cmd = 'load the audit data'
		insert	lnd.LoanQualityAudit
			(	OwnCd
			,	AcctNbr
			,	MjAcctTypCd
			,	CurrMiAcctTypCd
			,	Product
			,	ContractDate
			,	CurrAcctStatCd
			,	LoanLimitYN
			,	CallDate
			,	CreditScore
			,	RiskRatingCd
			,	TaxOwnerNbr
			,	TaxOwnerCd
			,	PrimaryOwnerZipCd
			,	NoteOpenAmt
			,	NoteIntRate
			,	NoteBal
			,	OwnerName
			,	OwnerSortName
			,	OriginatingPerson
			,	LoanOfficersNbr
			,	LoanOfficer
			,	OEMPRole
			,	SIGNRole
			,	MemberAgreeNbr
			,	IsEmployee
			,	LoadOn
			)
		select	OwnCd
			,	AcctNbr
			,	MjAcctTypCd
			,	CurrMiAcctTypCd
			,	Product
			,	ContractDate
			,	CurrAcctStatCd
			,	LoanLimitYN
			,	CallDate
			,	CreditScore
			,	RiskRatingCd
			,	TaxOwnerNbr
			,	TaxOwnerCd
			,	PrimaryOwnerZipCd
			,	NoteOpenAmt
			,	NoteIntRate
			,	NoteBal
			,	OwnerName
			,	OwnerSortName
			,	OriginatingPerson
			,	LoanOfficersNbr
			,	LoanOfficer
			,	OEMPRole
			,	SIGNRole
			,	MemberAgreeNbr
			,	IsEmployee
			,	@loadOn	as LoadOn
		from	openquery(RPT2,'
				select	/*+CHOOSE*/
						a.OwnCd
					,	a.AcctNbr
					,	a.MjAcctTypCd
					,	a.CurrMiAcctTypCd
					,	t.MiAcctTypDesc	as Product
					,	a.ContractDate
					,	a.CurrAcctStatCd
					,	l.LoanLimitYN
					,	l.CallDate
					,	l.CreditScore
					,	l.RiskRatingCd
					,	nvl(a.TaxRptForPersNbr, a.TaxRptForOrgNbr) as TaxOwnerNbr
					,	case nvl(a.TaxRptForPersNbr, 0)
						when a.TaxRptForPersNbr then ''Pers''
						else ''Org'' end							as TaxOwnerCd
					,	ca.ZipCd PrimaryOwnerZipCd
					,	u.OrigBal as NoteOpenAmt
					,	PACK_Acct.FUNC_Acct_RATE(a.AcctNbr, ''NOTE'', ''BAL'', trunc(sysdate))	as NoteIntRate
					,	PACK_Acct.FUNC_Acct_BAL(a.AcctNbr,''NOTE'', ''BAL'', trunc(sysdate))	as NoteBal
					,	trim(nvl(p.FirstName ||'' ''|| decode(p.MdlInit, null, null, p.MdlInit ||''. '') || p.LastName, o.OrgName))	as OwnerName
					,	trim(nvl(p.LastName ||'', ''|| p.FirstName ||'' ''|| p.MdlInit, o.OrgName))					as OwnerSortName
					,   p2.FirstName ||'' ''|| decode(p2.MdlInit, null, null, p2.MdlInit ||''.'') || p2.LastName	as OriginatingPerson
					,	p3.PersNbr									as LoanOfficersNbr
					,	p3.FirstName ||'' ''|| decode(p3.MdlInit, null, null, p3.MdlInit ||''. '') || p3.LastName	as LoanOfficer
					,	r.AcctRoleCD								as OEMPRole
					,	s.AcctRoleCD								as SIGNRole
					,	ma.MemberAgreeNbr
					,	case when pe.PersNbr is null then 0 else 1 end as IsEmployee
				from	Acct				a
				join	AcctLoan			l
						on	a.AcctNbr = l.AcctNbr
				join	MjMiAcctTyp			t
						on	a.MjAcctTypCd		= t.MjAcctTypCd
						and a.CurrMiAcctTypCd	= t.MiAcctTypCd
				join	MemberAgreement		ma
						on	nvl(a.TaxRptForOrgNbr , 0) = nvl(ma.PrimaryOrgNbr , 0)
						and	nvl(a.TaxRptForPersNbr, 0) = nvl(ma.PrimaryPersNbr, 0)
				left join
						Pers 				p
						on	a.TaxRptForPersNbr = p.PersNbr
				left join
						Org					o
						on	a.TaxRptForOrgNbr = o.OrgNbr
				left join
						PersEmpl			pe
						on	a.TaxRptForPersNbr	= pe.PersNbr
						and	pe.InactiveDate		is null
				left join
						AcctAcctRolePers	r
						on	a.AcctNbr		= r.AcctNbr
						and	r.AcctRoleCd	= ''OEMP''
				left join 	Pers 				p2
							on	r.PersNbr = p2.PersNbr
				left join	AcctAcctRolePers	r2
							on	a.AcctNbr = r2.AcctNbr
							and	r2.AcctRoleCD = ''LOFF''
				left join 
						Pers 				p3
						on	r2.PersNbr = p3.PersNbr
				left join
						texans.Current_AddrUse_VW	cau
						on	nvl(a.TaxRptForOrgNbr , 0) = nvl(cau.OrgNbr , 0)
						and	nvl(a.TaxRptForPersNbr, 0) = nvl(cau.PersNbr, 0)
						and cau.AddrUseCd	= ''PRI''
				left join
						addr			 ca
						on	cau.AddrNbr = ca.AddrNbr
				left join
						AcctAcctRolePers	s
						on	a.AcctNbr		= s.AcctNbr
						and	s.AcctRoleCd	= ''SIGN''
				left join
						AcctSUBAcct		u
						on	a.AcctNbr	= u.AcctNbr
						and u.BalCatCd	= ''NOTE''
						and u.BalCatCd	= ''BAL''
				where	a.ContractDate > trunc(sysdate) - 8');

		set	@cmd = 'update data from the wh_AcctLoan table'
		update	a
		set		TotalPi			= l.TotalPi
			,	PmtMethCd		= l.PmtMethCd
			,	CreditLimitAmt	= l.CreditLimitAmt
		from	lnd.LoanQualityAudit	a
		join	openquery(RPT2, '
				select	l.AcctNbr
					,	l.TotalPi
					,	l.PmtMethCd
					,	l.CreditLimitAmt
				from	wh_AcctLoan	l
				join	Acct		a
						on	l.AcctNbr = a.AcctNbr
				where	l.EffDate		= (	select	max(EffDate)
											from	wh_AcctLoan
											where	AcctNbr = l.AcctNbr )
				and		a.ContractDate	> trunc(sysdate) - 8'
			)	l on a.AcctNbr = l.AcctNbr
		where	a.LoadOn = @loadOn;

		--	set the results for notification
		select	@cmd	= ''
			,	@detail	= ''
			,	@result	= 2;	--	information

	end try
	begin catch
		--	collect the standard error message...
		exec tcu.ErrorDetail_get @detail out;
		set @result = 1;	--	failure
	end catch;
end;

--	save the results...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @cmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO