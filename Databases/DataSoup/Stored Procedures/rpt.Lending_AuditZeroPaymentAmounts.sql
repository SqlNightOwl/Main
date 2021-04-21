use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditZeroPaymentAmounts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditZeroPaymentAmounts]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditZeroPaymentAmounts
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Payment Not Equal Zero' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/09/2009  Deeksha			Problem:	Few AcctNbr had TotalPI Amts on them but 
										were not showing.
							Reason:		When data is pulled on weekly basis from
										OSI, the TotalPI column pulled from the
										wh_AcctLoan table did not have latest data.
							Solution:	Re-Query just those AcctNbrs and update the
										lnd.LoanQualityAudit.
										Next time the sp is executed it won't need
										to re-query and update.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(max)
,	@list	nvarchar(max)
,	@return	int;

set	@userId = substring(@userId, charindex('\', @userId) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @userId;

--	update any loans with blank P&I ammounts for this load date...
if exists (	select	top 1 RowId	from lnd.LoanQualityAudit
			where	LoadOn			= @AuditDate
			and		MjAcctTypCd		= 'CNS'
			and		CurrAcctStatCd	= 'ACT'
			and		CurrMiAcctTypCd	not in ('PLOC','RLOC')
			and		TotalPI			is null	)
begin
	--	update the table with the total principal and interest amount
	select	@list	= isnull(@list, cast(AcctNbr as varchar(22)))
					+ ',' + cast(AcctNbr as varchar(22))
	from	lnd.LoanQualityAudit
	where	LoadOn			= @AuditDate
	and		MjAcctTypCd		= 'CNS'
	and		CurrAcctStatCd	= 'ACT'
	and		CurrMiAcctTypCd	not in ('PLOC','RLOC')
	and		TotalPI			is null
	order by AcctNbr;

	--	build and execute the sql command
	set	@cmd = 'update a
	set		TotalPI = l.TotalPI
	from	lnd.LoanQualityAudit	a
	join	openquery(OSI, ''
			select	l.AcctNbr
				,	l.TotalPI
			from	wh_AcctLoan	l
			where	l.AcctNbr	in (' + @list + ')
			and		l.EffDate	= (	select	max(EffDate) from wh_AcctLoan
									where	AcctNbr = l.AcctNbr )'')
			l	on	a.AcctNbr = l.AcctNbr
	where	a.AcctNbr	in (' + @list + ');'

	exec sp_executesql @cmd;
end;

--	return the results...
select	OriginatingPerson
	,	AcctNbr
	,	ContractDate
	,	CurrMiAcctTypCd
	,	TotalPI
from	lnd.LoanQualityAudit
where	LoadOn			= @AuditDate
and		MjAcctTypCd		= 'CNS'
and		CurrAcctStatCd	= 'ACT'
and		CurrMiAcctTypCd	not in ('PLOC','RLOC')
order by OriginatingPerson;

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