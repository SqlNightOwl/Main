use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditMissingProperty]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditMissingProperty]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditMissingProperty
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/01/2009
Purpose  :	Retrieves 'Audit Missing Property' Data for SQL Reporting purposes.
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
	,	a.AcctNbr
	,	a.ContractDate
	,	a.OwnerSortName
	,	a.NoteOpenAmt
	,	a.NoteBal
	,	a.Product
	,	a.CurrMiAcctTypCd
from	lnd.LoanQualityAudit	a
left outer join
		openquery(OSI, '
		select	AcctNbr
			,	PropNbr
		from	AcctProp')
		b	on	a.AcctNbr = b.AcctNbr
where	a.LoadOn			=	@AuditDate
and		a.MjAcctTypCd		in	('CML','CNS','MTG')
and		a.CurrAcctStatCd	=	'ACT'
and		a.CurrMiAcctTypCd	not	in	('RCCC','RCCD','RCSG','RCSS','RLOC','ROCD','ROSG','RPLC','RVCD','RVSS','SBA3','V06','V09','V17')
and		b.PropNbr			is	null
order by
		a.OriginatingPerson
	,	a.ContractDate;

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