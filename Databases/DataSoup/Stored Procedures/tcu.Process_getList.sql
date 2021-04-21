use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_getList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_getList]
GO
setuser N'tcu'
GO
create procedure tcu.Process_getList
as

set nocount on;

select	ProcessCategory
	,	ProcessId
	,	Process
from	tcu.Process
where	process not like '%RETIRED%'
order by ProcessCategory, Process
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Process_getList]  TO [wa_Process]
GO