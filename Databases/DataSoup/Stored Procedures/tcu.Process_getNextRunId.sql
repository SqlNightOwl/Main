use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_getNextRunId]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_getNextRunId]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_getNextRunId
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/01/2009
Purpose  :	Returns the next available Run Id for the Process Log & Que tables.
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare @runId int

set @runId = 0;

begin transaction

	select	@RunId		= cast(Value as int) + 1
	from	tcu.Dictionary
	where	Application	= 'Process'
	and		Name		= 'Last Run';

	update	tcu.Dictionary with (tablockx)
	set		Value		= cast(@RunId as varchar(10))
	where	Application	= 'Process'
	and		Name		= 'Last Run';

	if @@rowcount = 0 set @RunId = 0;

commit transaction;

return @runId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Process_getNextRunId]  TO [wa_Process]
GO