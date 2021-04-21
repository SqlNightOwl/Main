use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_getLastLoaded]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_getLastLoaded]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Employee_getLastLoaded
	@LastLoaded	datetime	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/25/2008
Purpose  :	Returns the last date/time the employee table was sucessfully loaded
			from the HR Employee extract file.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	@LastLoaded	= convert(char(19), max(UpdatedOn), 121)
from	tcu.Employee
where	UpdatedBy = 'HR Import';

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Employee_getLastLoaded]  TO [wa_Services]
GO