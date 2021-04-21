use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ValueType_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ValueType_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ValueType_get
	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/14/2008
Purpose  :	Retrieves ValueTypes from the CK_ValueType  rule.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@error	int
,	@proc	varchar(255)
,	@value	varchar(1000);

set	@error	= 0;
set	@proc	= db_name() + '.' + object_name(@@procid) + '.';

select	@value = cast(text as varchar(1000))
from	sys.syscomments
where	id	= object_id(N'[dbo].[CK_ValueType]');

select	ValueType = value
from	tcu.fn_split(@value, '''')
where	charindex('valuetype', value) = 0
and		charindex(')', value) = 0
order by value;

set	@error = @@error;

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc;

return @error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO