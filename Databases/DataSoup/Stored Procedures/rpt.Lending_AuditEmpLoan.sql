use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditEmpLoan]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditEmpLoan]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditEmpLoan
	@AuditDate	datetime
,	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	11/30/2009
Purpose  :	Retrieves 'Audit Employee Loans' Data for SQL Reporting purposes.
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

select	AcctNbr
	,	OwnerSortName
	,	ContractDate
	,	OriginatingPerson
	,	NoteBal
	,	CurrMiAcctTypCd
	,	LoanOfficer
from	lnd.LoanQualityAudit
where	LoadOn			=	@AuditDate
and		MjAcctTypCd		=	'CNS'
and		CurrAcctStatCd	=	'ACT'
and		IsEmployee		=	1
and		LoanOfficersNbr	!=	2296;	--	Employee Loan person record

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