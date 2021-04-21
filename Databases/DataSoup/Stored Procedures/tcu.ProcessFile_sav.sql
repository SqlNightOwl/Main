use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessFile_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessFile_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessFile_sav
	@ProcessId		smallint
,	@FileName		varchar(50)
,	@TargetFile		varchar(50)		= null
,	@AddDate		bit
,	@IsRequired		bit
,	@ApplName		nvarchar(60)	= null
,	@ApplFrequency	int
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	11/16/2007
Purpose  :	Inserts/Updates a record in the ProcessFile table based upon the 
			primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/13/2008 	Fijula Kuniyil	Added ApplFrequency field for indicating frequency
							of OSI file 
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
update	tcu.ProcessFile
set		TargetFile		= nullif(rtrim(isnull(@TargetFile, TargetFile)), '')
	,	AddDate			= isnull(@AddDate, AddDate)
	,	IsRequired		= isnull(@IsRequired, IsRequired)
	,	ApplName		= nullif(isnull(@ApplName, ApplName), '')
	,	ApplFrequency	= isnull(@ApplFrequency, ApplFrequency)
	,	UpdatedBy		= tcu.fn_UserAudit()
	,	UpdatedOn		= getdate()
where	ProcessId	= @ProcessId
and		FileName	= @FileName

select	@error	= @@error
	,	@rows	= @@rowcount

--	if no rows were updated then try the insert.
if @rows = 0
begin
	set @method = 'insert'

	insert	tcu.ProcessFile
		(	ProcessId
		,	FileName
		,	TargetFile
		,	AddDate
		,	IsRequired
		,	ApplName
		,	ApplFrequency
		,	CreatedBy
		,	CreatedOn	)
	values
		(	@ProcessId
		,	ltrim(rtrim(@FileName))
		,	nullif(ltrim(rtrim(@TargetFile)), '')
		,	isnull(@AddDate		, 0)
		,	isnull(@IsRequired	, 0)
		,	isnull(@ApplName	, '')
		,	isnull(@ApplFrequency, 0)
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
GRANT  EXECUTE  ON [tcu].[ProcessFile_sav]  TO [wa_Process]
GO