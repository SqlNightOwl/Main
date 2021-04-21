use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ScanDetail_getSeverity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[ScanDetail_getSeverity]
GO
setuser N'risk'
GO
CREATE procedure risk.ScanDetail_getSeverity
	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/01/2009
Purpose  :	Retrieves Scan severity types
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0;
set	@proc	= db_name() + '.' + object_name(@@procid) + '.';

select	s.Value as Severity
from	sys.check_constraints				c
cross apply 
		tcu.fn_split(c.definition, '''')	s
where	c.[schema_id]	= 11
and		c.name			= 'CK_ScanDetail_Severity'
and		s.Value			not like '%='
and		s.Value			!= ')'
order by s.Value;

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
GRANT  EXECUTE  ON [risk].[ScanDetail_getSeverity]  TO [wa_SecurityScan]
GO