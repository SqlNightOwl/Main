use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessChain_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessChain_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessChain_get
	@ScheduledProcessId		smallint		= null
,	@ChainedProcessId		smallint		= null
,	@errmsg					varchar(255)	= null	output	-- in case of error
,	@debug					tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	12/26/2007
Purpose  :	Retrieves record(s) from the ProcessChain table based upon the primary
			key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

select  ch.ScheduledProcessId
	,	ch.ChainedProcessId
	,	ch.ChainedProcessName
	,	ch.Sequence
	,	ch.CancelChainOnError
	,	ParentProcessName	= pr.Process
from	tcu.Process		pr
right join
	(	select	c.ScheduledProcessId
			,	c.ChainedProcessId
			,	p.Process as ChainedProcessName
			,	c.Sequence
			,	c.CancelChainOnError
		from	tcu.ProcessChain	c
		join	tcu.Process			p
				on  c.ChainedProcessId  	= p.ProcessId
				and	c.ScheduledProcessId	= isnull(@ScheduledProcessId, c.ScheduledProcessId)
				and	c.ChainedProcessId		= isnull(@ChainedProcessId, c.ChainedProcessId)
	)	ch	on	ch.ScheduledProcessId = pr.ProcessId

set	@error = @@error

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @errmsg) with log
end

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[ProcessChain_get]  TO [wa_Process]
GO