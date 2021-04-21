use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_sav
	@ProcessId				smallint
,	@Process				varchar(50)
,	@ProcessType			char(3)
,	@ProcessCategory		varchar(20)
,	@ProcessHandler			nvarchar(256)	= null
,	@ProcessOwner			varchar(20)		= null
,	@Description			varchar(255)
,	@IncludeRunInfo			bit
,	@SkipFederalHolidays	bit
,	@SkipCompanyHolidays	bit
,	@IsEnabled				bit
,	@errmsg					varchar(255)	= null	output	-- in case of error
,	@debug					tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul hunter
Created  :	10/23/2007
Purpose  :	Inserts/Updates a record in the Process table based upon the primary
			key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error	int
,	@method	varchar(6)
,	@now	datetime
,	@proc	varchar(255)
,	@rows	int
,	@user	varchar(25)

select	@error	= 0
	,	@method	= 'update'
	,	@now	= getdate()
	,	@rows	= 0
	,	@user	= tcu.fn_UserAudit();

if isnull(@ProcessId, 0) = 0
	set	@ProcessId = tcu.fn_Process_NextId(@ProcessType);

--	try doing an update first...
update	tcu.Process
set		Process				= isnull(@Process						, Process)
	,	ProcessType			= isnull(@ProcessType					, ProcessType)
	,	ProcessCategory		= isnull(@ProcessCategory				, ProcessCategory)
	,	ProcessHandler		= nullif(rtrim(isnull(@ProcessHandler	, ProcessHandler))	, '')
	,	ProcessOwner		= nullif(rtrim(isnull(@ProcessOwner		, ProcessOwner))	, '')
	,	Description			= isnull(@Description					, [Description])
	,	IncludeRunInfo		= isnull(@IncludeRunInfo				, IncludeRunInfo)
	,	SkipFederalHolidays	= isnull(@SkipFederalHolidays			, SkipFederalHolidays)
	,	SkipCompanyHolidays	= isnull(@SkipCompanyHolidays			, SkipCompanyHolidays)
	,	IsEnabled			= isnull(@IsEnabled						, IsEnabled)
	,	UpdatedBy			= @user
	,	UpdatedOn			= @now
where	ProcessId			= @ProcessId;

select	@error	= @@error
	,	@rows	= @@rowcount;

--	if no rows were updated then try the insert.
if	@rows	= 0
and	@error	= 0
begin
	set @method = 'insert';

	insert	tcu.Process
		(	ProcessId
		,	Process
		,	ProcessType
		,	ProcessCategory
		,	ProcessHandler
		,	ProcessOwner
		,	Description
		,	IncludeRunInfo
		,	SkipFederalHolidays
		,	SkipCompanyHolidays
		,	IsEnabled
		,	CreatedBy
		,	CreatedOn
		)
	values
		(	@ProcessId
		,	@Process
		,	@ProcessType
		,	@ProcessCategory
		,	nullif(rtrim(@ProcessHandler)	, '')
		,	nullif(rtrim(@ProcessOwner)		, '')
		,	@Description
		,	@IncludeRunInfo
		,	@SkipFederalHolidays
		,	@SkipCompanyHolidays
		,	@IsEnabled
		,	@user
		,	@now
		);

	set	@error = @@error;

end; -- else (insert)

PROC_EXIT:
if @error != 0
begin
	select	@errmsg = @proc + '(' + @method + ')'
		,	@proc	= db_name() + '.'  + object_name(@@procid) + '.';
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
GRANT  EXECUTE  ON [tcu].[Process_sav]  TO [wa_Process]
GO