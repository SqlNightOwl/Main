use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessNotification_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessNotification_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessNotification_sav
	@ProcessId		smallint
,	@MessageTypes	tinyint
,	@Recipient		varchar(75)
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	11/16/2007
Purpose  :	Inserts/Updates a record in the ProcessNotification table based upon 
			the primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error	int
,	@method	varchar(6)
,	@proc	varchar(255)
,	@rows	int

set @method = 'update';
set	@error	= 0;
set	@proc	= db_name() + '.' + object_name(@@procid) + '.';

--	try doing an update first...
update	tcu.ProcessNotification
set		MessageTypes	= isnull(@MessageTypes, MessageTypes)
	,	UpdatedBy		= tcu.fn_UserAudit()
	,	UpdatedOn		= getdate()
where	ProcessId		= @ProcessId
and		Recipient		= @Recipient;

select	@error	= @@error
	,	@rows	= @@rowcount;

--	if no rows were updated then try the insert.
if @rows = 0
begin
	set @method = 'insert';

	insert	tcu.ProcessNotification
		(	ProcessId
		,	MessageTypes
		,	Recipient
		,	CreatedBy
		,	CreatedOn
		)
	values
		(	@ProcessId
		,	@MessageTypes
		,	@Recipient
		,	tcu.fn_UserAudit()
		,	getdate()
		);

	set	@error = @@error;

end;	-- else (insert)

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc + '(' + @method + ')';
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @errmsg) with log;
end;

return @error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[ProcessNotification_sav]  TO [wa_Process]
GO