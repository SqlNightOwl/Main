use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Device_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[Device_get]
GO
setuser N'risk'
GO
CREATE procedure risk.Device_get
	@AssignedTo		int			= null
,	@DeviceType		varchar(10)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/10/2009
Purpose  :	Returns the device details 
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int;

 select	d.DeviceId
	,	d.Device
	,	d.ExtendedName
	,	d.DeviceType
	,	d.AssignedTo
	,	e.Employee
from	risk.Device		d
left join
		risk.Employee_v	e
		on	d.AssignedTo = e.EmployeeNumber
where		(d.AssignedTo	= @AssignedTo	or @AssignedTo	is null )
and			(d.DeviceType	= @DeviceType	or @DeviceType	is null )
order by d.Device

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [risk].[Device_get]  TO [wa_SecurityScan]
GO