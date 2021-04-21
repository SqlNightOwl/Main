use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Application_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Application_get]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Application_get
	@Application	varchar(125)	= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/01/2005
Purpose  :	Inserts/Updates a record in the tcu.Application table based upon the 
			primary key.
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

select	Application
	,	Description
from	tcu.Application
where	Application	= isnull(@Application, Application)

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