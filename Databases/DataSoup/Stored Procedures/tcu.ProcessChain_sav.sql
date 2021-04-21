use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessChain_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessChain_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessChain_sav
	@ScheduledProcessId		smallint
,	@ChainedProcessId		smallint
,	@Sequence				tinyint
,	@CancelChainOnError		bit
,	@errmsg					varchar(255)	= null	output	-- in case of error
,	@debug					tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	12/26/2007
Purpose  :	Inserts/Updates a record in the ProcessChain table based upon the 
			primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/23/2008	Paul Hunter		Disabled the ability to Chain and "On Demand" Process.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@method	varchar(6)
,	@proc	varchar(255)
,	@rows	int

set	@method	= 'update'
set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	On Demand processes cannot be chained
if exists (	select	top 1 * from tcu.Process
			where	ProcessCategory	= 'On Demand'
			and		ProcessId in (@ScheduledProcessId, @ChainedProcessId)	)
begin
	goto PROC_EXIT
end	

--	try doing an update first...
update	tcu.ProcessChain
set		Sequence			= isnull(@Sequence, Sequence)
	,	CancelChainOnError	= isnull(@CancelChainOnError, CancelChainOnError)
	,	UpdatedBy			= tcu.fn_UserAudit()
	,	UpdatedOn			= getdate()
where	ScheduledProcessId	= @ScheduledProcessId
and		ChainedProcessId	= @ChainedProcessId

select	@error	= @@error
	,	@rows	= @@rowcount

--	if no rows were updated then try the insert.
if @rows = 0
begin
	set @method = 'insert'

	insert	tcu.ProcessChain
		(	ScheduledProcessId
		,	ChainedProcessId
		,	Sequence
		,	CancelChainOnError
		,	CreatedBy
		,	CreatedOn	)
	values
		(	@ScheduledProcessId
		,	@ChainedProcessId
		,	@Sequence
		,	@CancelChainOnError
		,	tcu.fn_UserAudit()
		,	getdate()	)

	set	@error = @@error

end -- else (insert)

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc + '(' + @method + ')'
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
GRANT  EXECUTE  ON [tcu].[ProcessChain_sav]  TO [wa_Process]
GO