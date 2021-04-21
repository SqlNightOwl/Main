use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Dictionary_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Dictionary_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Dictionary_get
	@Application	varchar(125)	= null
,	@Name			varchar(125)	= null
,	@AsOutput		tinyint			= 0
,	@Value			varchar(4000)	= null	output	-- enable use by other stored procedures
,	@ValueType		varchar(8)		= null	output	-- enable use by other stored procedures
,	@Description	varchar(1000)	= null	output	-- enable use by other stored procedures
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/18/2005
Purpose  :	Retrieves record(s) from the tcuDictionary table based upon the
			primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error		int
,	@proc		varchar(255)

set	@error		= 0
set	@proc		= db_name() + '.' + object_name(@@procid) + '.'
set	@AsOutput	= isnull(@AsOutput, 0)

if isnull(@AsOutput, 0) != 0
begin
	select	@Value			= Value
		,	@ValueType		= ValueType
		,	@Description	= Description
	from	tcu.Dictionary
	where	Application		= @Application
	and		Name			= @Name
end
else
begin
	select	Application
		,	Name
		,	Value
		,	ValueType
		,	Description
	from	tcu.Dictionary
	where	Application	= isnull(@Application, Application)
	and		Name		= isnull(@Name, Name)
end

set	@error = @@error

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Dictionary_get]  TO [wa_Marketing]
GO