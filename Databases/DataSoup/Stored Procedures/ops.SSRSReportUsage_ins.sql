use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[SSRSReportUsage_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[SSRSReportUsage_ins]
GO
setuser N'ops'
GO
CREATE procedure ops.SSRSReportUsage_ins
	@objectId	int
,	@ssrsUser	varchar(25)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	06/15/2009
Purpose  :	Recording the SSRS Reports Usage.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/26/2010	Paul Hunter		Added UserId parameter to pass in the caller id from
							SSRS.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@object	sysname
,	@return	int
,	@userId	varchar(25)

set	@object = object_name(@objectId);

select	@userId = rtrim(left(isnull(substring(@ssrsUser, charindex('\', @ssrsUser) + 1, 25), nt_username), 25))
from	sys.sysprocesses
where	spid =  @@spid;

insert	ops.SSRSReportUsage
	(	ObjectName
	,	UserId
	,	RunOn
	)
select	@object
	,	@userId
	,	getdate();

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO