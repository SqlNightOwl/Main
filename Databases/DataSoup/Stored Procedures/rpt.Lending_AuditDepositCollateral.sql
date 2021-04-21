use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditDepositCollateral]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditDepositCollateral]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditDepositCollateral
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
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

declare
	@return	int;

set	@userId = substring(@userId, charindex('\', @userId) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @userId;

select	a.OriginatingPerson
	,	a.ContractDate
	,	a.AcctNbr
	,	a.NoteBal
	,	b.AcctNbr	as CollateralAcctNbr
	,	b.HoldPct
from	lnd.LoanQualityAudit	a
left outer join
		openquery(OSI, '
		select	AcctNbr
			,	LoanAcctNbr
			,	HoldPct
		from	AcctClatAcct')
		b	on	a.AcctNbr = b.LoanAcctNbr
where	a.LoadOn			=	@AuditDate
and		a.CurrAcctStatCd	=	'ACT'
and		a.CurrMiAcctTypCd	in	('RCCD','ROCD','RVSS')
and		b.AcctNbr is null;

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