use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[Lending_AuditCallDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[Lending_AuditCallDate]
GO
setuser N'rpt'
GO
CREATE procedure rpt.Lending_AuditCallDate
	@userId		varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	11/20/2009
Purpose  :	Retrieves 'Audit Call Date' Data for SQL Reporting purposes.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/21/2010	Deeksha			Audit Call Date query made into dynamic query.  
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int;

set	@userId = substring(@userId, charindex('\', @userId) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @userId;

select	OriginatingPerson
	,	AcctNbr
	,	ContractDate
	,	CallDate 
from	openquery(OSI, '
		select	a.OriginatingPerson
			,	a.AcctNbr
			,	a.ContractDate
			,	l.CallDate 
		from	wh_AcctCommon	a
		join	AcctLoan		l
				on a.AcctNbr = l.AcctNbr
		where	a.EffDate			= ( select	max(EffDate) from wh_AcctCommon
										where	AcctNbr = l.AcctNbr	)
		and		a.CurrAcctStatCd	= ''ACT''
		and		l.CallDate			is not null')
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