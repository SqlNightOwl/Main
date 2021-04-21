use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Device_upd]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[Device_upd]
GO
setuser N'risk'
GO
CREATE procedure risk.Device_upd
	@DeviceId		int
,	@ExtendedName	varchar(75)	= null
,	@DeviceType		varchar(10)	= null
,	@AssignedTo		int			= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/14/2009
Purpose  :	
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int

update	risk.Device
set		ExtendedName	= nullif(rtrim(isnull(@ExtendedName	, ExtendedName)), '')
	,	DeviceType		= nullif(rtrim(isnull(@DeviceType	, DeviceType))	, '')
	,	AssignedTo		= isnull(isnull(@AssignedTo, AssignedTo), 0)
	,	UpdatedBy		= tcu.fn_UserAudit()
	,	UpdatedOn		= getdate()
where	DeviceId		= @DeviceId

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
GRANT  EXECUTE  ON [risk].[Device_upd]  TO [wa_SecurityScan]
GO