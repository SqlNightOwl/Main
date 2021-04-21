use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Application_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Application_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Application_sav
	@Application	varchar(125)
,	@Description	varchar(2000)	= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last

as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/01/2005
Purpose  :	Inserts/Updates a record in the tcuApplication table based upon the
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

update	tcu.Application
set		Description		= nullif(rtrim(isnull(@Description, Description)), '')
	,	UpdatedOn		= getdate()
	,	UpdatedBy		= tcu.fn_UserAudit()
where	Application	= @Application

select	@error	= @@error
	,	@rows	= @@rowcount

if @rows = 1 and @error = 0
begin

	set @method = 'insert'

	insert	tcu.Application
		(	Application
		,	Description
		,	CreatedOn
		,	CreatedBy	)
	values
		(	@Application
		,	nullif(rtrim(@Description), '')
		,	getdate()
		,	tcu.fn_UserAudit()	)

	set	@error = @@error

end	--	insert

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc + @method

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO