use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Scan_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[Scan_get]
GO
setuser N'risk'
GO
CREATE procedure risk.Scan_get
	@ScanId			smallint	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/16/2009
Purpose  :	Returns the Scans for display in filter.	
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int

select	ScanId
	,	Scan
	,	ScanType
	,	ScanOn
	,	Company
	,	Description
	,	RequestorBy
	,	RequestedOn
	,	SubmittedBy
	,	SubmittedOn
from	risk.Scan
where	(ScanId		= @ScanId	or	@ScanId	is null)

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
GRANT  EXECUTE  ON [risk].[Scan_get]  TO [wa_SecurityScan]
GO