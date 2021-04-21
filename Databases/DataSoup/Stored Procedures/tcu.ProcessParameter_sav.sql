use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessParameter_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessParameter_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessParameter_sav
	@ProcessId		smallint
,	@Parameter		varchar(20)
,	@Value			varchar(4000)
,	@ValueType		varchar(10)
,	@Description	varchar(255)
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	11/16/2007
Purpose  :	Inserts/Updates a record in the ProcessParameter table based upon the
			primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@method	varchar(6)
,	@proc	varchar(255)
,	@rows	int

set @method = 'update'
set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	try doing an update first...
update	tcu.ProcessParameter
set		Value		= isnull(@Value, Value)
	,	ValueType	= isnull(@ValueType, ValueType)
	,	Description	= isnull(@Description, Description)
	,	UpdatedBy	= tcu.fn_UserAudit()
	,	UpdatedOn	= getdate()
where	ProcessId	= @ProcessId
and		Parameter	= @Parameter

select	@error	= @@error
	,	@rows	= @@rowcount

--	if no rows were updated then try the insert.
if @rows = 0
begin
	set @method = 'insert'

	insert	tcu.ProcessParameter
		(	ProcessId
		,	Parameter
		,	Value
		,	ValueType
		,	Description
		,	CreatedBy
		,	CreatedOn	)
	values
		(	@ProcessId
		,	@Parameter
		,	@Value
		,	@ValueType
		,	@Description
		,	tcu.fn_UserAudit()
		,	getdate()	)

	set	@error = @@error

end -- else (insert)

proc_exit:
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
GRANT  EXECUTE  ON [tcu].[ProcessParameter_sav]  TO [wa_Process]
GO