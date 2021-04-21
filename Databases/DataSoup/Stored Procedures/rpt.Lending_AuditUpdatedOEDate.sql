use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditUpdatedOEDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditUpdatedOEDate]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditUpdatedOEDate
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
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

declare
	@openEndPlus	char(10)
,	@return			int;

set	@userId = substring(@userId, charindex('\', @userId) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @userId;

set	@openEndPlus = convert(char(10), cast(tcu.fn_Dictionary('Loan Audits','Open End Plus') as datetime), 101)

select	a.OriginatingPerson
	,	a.ContractDate
	,	a.AcctNbr
	,	a.OwnerName
	,	a.CurrMiAcctTypCd
	,	a.TaxOwnerNbr		as PersNbr
	,	b.Value
from	lnd.LoanQualityAudit	a
join	openquery(OSI, '
		select	PersNbr
			,	Value
		from	PersUserField
		where	UserFieldCd = ''LLOE''')
		b	on	a.TaxOwnerNbr = b.PersNbr
where	LoadOn			=	@AuditDate
and		CurrMiAcctTypCd	in	('RLOC','ROAN','ROAU','ROCB','ROCD','RODR','ROSG','ROST','RVSS')
and	(	b.Value			<  @openEndPlus
	or	b.Value			is null )
order by b.Value;

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