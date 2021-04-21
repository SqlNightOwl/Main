use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditCalcSchdLOC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditCalcSchdLOC]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditCalcSchdLOC
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
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

declare
	@return	int;

set	@userId = substring(@userId, charindex('\', @userId) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @userId;

select  a.OriginatingPerson
	,	a.AcctNbr
	,	a.NoteIntRate
	,	b.CalcSchedName
	,	a.CreditScore
	,	a.CreditLimitAmt
	,	a.ContractDate	
from	lnd.LoanQualityAudit	a
join	openquery(OSI, '
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
		and	(	i.EffDate		= (	select max(EffDate) from AcctIntHist
									where   AcctNbr		= i.AcctNbr
									and		SubAcctNbr	= i.SubAcctNbr
									and		InactiveDate is null	)
			or	i.EffDate		is null    )')
		b	on a.AcctNbr = b.AcctNbr
where	a.LoadOn			= @AuditDate
and		a.MjAcctTypCd		= 'CNS'
and		a.CurrAcctStatCd	= 'ACT'
and		a.CurrMiAcctTypCd	= 'RLOC'
order by
		a.OriginatingPerson
	,	a.NoteIntRate;

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO