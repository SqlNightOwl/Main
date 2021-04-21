use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Dictionary_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Dictionary_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Dictionary_sav
	@Application	varchar(125)
,	@Name			varchar(125)
,	@Value			varchar(4000)	= null
,	@ValueType		varchar(8)		= null
,	@Description	varchar(1000)	= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/14/2005
Purpose  :	Inserts/Updates a record in the tcuDictionary table based upon the 
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

update	tcu.Dictionary
set		Value		= nullif(rtrim(isnull(@Value, Value)),	'')
	,	ValueType	= isnull(@ValueType, ValueType)
	,	Description	= nullif(rtrim(isnull(@Description, Description)),	'')
	,	UpdatedOn	= getdate()
	,	UpdatedBy	= tcu.fn_UserAudit()
where	Application	= @Application
and		Name		= @Name

select	@error	= @@error
	,	@rows	= @@rowcount

if @error = 0 and @rows = 0
begin

	set @method = 'insert'

	insert	tcu.Dictionary
		(	Application
		,	Name
		,	Value
		,	ValueType
		,	Description
		,	CreatedOn
		,	CreatedBy	)
	values
		(	nullif(rtrim(@Application),	'')
		,	nullif(rtrim(@Name),		'')
		,	nullif(rtrim(@Value),		'')
		,	isnull(@ValueType,			'string')
		,	nullif(rtrim(@Description),	'')
		,	getdate()
		,	tcu.fn_UserAudit()	)

	set	@error = @@error

end --	insert

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