use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventField_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[EventField_get]
GO
setuser N'mkt'
GO
CREATE procedure mkt.EventField_get
	@EventId	int				= null
,	@Field		varchar(255)	= null
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/15/2006
Purpose  :	Retrieves record(s) from the mktEventField table based upon the primary key.
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

select	EventId
	,	Field
	,	FieldNumber
	,	IsRequired
	,	FieldCaption
	,	FieldType
	,	ListOfValues
from	mkt.EventField
where	(EventId	= @EventId	or @EventId is null)
and		(Field		= @Field	or @Field is null)

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
GRANT  EXECUTE  ON [mkt].[EventField_get]  TO [wa_Marketing]
GO