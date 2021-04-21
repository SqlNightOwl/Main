use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Device_getDeviceType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[Device_getDeviceType]
GO
setuser N'risk'
GO
CREATE procedure risk.Device_getDeviceType
	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/15/2009
Purpose  :	Retrieves device types
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

select	distinct
		DeviceType
from	risk.Device
group by DeviceType
order by DeviceType;

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
GRANT  EXECUTE  ON [risk].[Device_getDeviceType]  TO [wa_SecurityScan]
GO