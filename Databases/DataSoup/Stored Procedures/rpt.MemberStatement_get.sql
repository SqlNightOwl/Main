use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[MemberStatement_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[MemberStatement_get]
GO
setuser N'rpt'
GO
CREATE procedure rpt.MemberStatement_get
	@Member		bigint
,	@ssrsUser	varchar(25)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/26/2010
Purpose  :	Returns the current raw statement data for the member number provided.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int;

set	@ssrsUser = substring(@ssrsUser, charindex('\', @ssrsUser) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @ssrsUser;

select	RecordId
	,	Record
	,	Account
from	osi.Statement
where	Member = @Member
order by RecordId;

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