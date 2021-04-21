use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditPaymentMethod]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditPaymentMethod]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditPaymentMethod
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Payment Method' Data for SQL Reporting purposes.
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

select	a.AcctNbr
	,	a.PmtMethCd
	,	a.Product
	,	a.OriginatingPerson
	,	b.PmtCalPeriodCd
	,	a.ContractDate
from	lnd.LoanQualityAudit	a
join	openquery(OSI, '
		select	AcctNbr
			,	PmtCalPeriodCd
		from	AcctLoanPmtHist	h
		where	EffDate = (	select max(EffDate) from AcctLoanPmtHist
							where	AcctNbr = h.AcctNbr )')
		b	on	a.AcctNbr = b.AcctNbr
where	a.LoadOn		=	@AuditDate
and		a.MjAcctTypCd	=	'CNS'
and		a.PmtMethCd		in	('AUTO','BILL')
order by
		a.AcctNbr
	,	a.Product;

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