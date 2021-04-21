use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ScanDetail_assignDevice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[ScanDetail_assignDevice]
GO
setuser N'risk'
GO
CREATE procedure risk.ScanDetail_assignDevice
	@ScanId		smallint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/01/2009
Purpose  :	Runs thru the ScanDetail for the specified Scan and assigns/looks up
			the DeviceId for each unique IP address.
History  :
   Date		Developer		Description  
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@address	varchar(15)
,	@deviceId	int

declare	@list	table
	(	ip	char(15)	primary key
	);

--	initialize the address variable...
set	@address = '';

--	first update records for device assignments for the static IP's
update	s
set		DeviceId	= i.DeviceId
	,	AssignedTo	= d.AssignedTo
	,	UpdatedBy	= null
	,	UpdatedOn	= null
from	risk.ScanDetail	s
join	risk.DeviceIP	i
		on	s.IP = i.IP
join	risk.Device		d
		on	i.DeviceId = d.DeviceId
where	s.ScanId = @ScanId;

--	create a unique list of the "unknown" IP addresses...
insert	@list
select	distinct
		IP
from	risk.ScanDetail
where	ScanId		= @ScanId
and		DeviceId	= 0
order by IP;

--	loop thru them and update the device id in the scan...
while exists (	select	top 1 ip from @list
				where	ip > @address	)
begin
	--	initialize the DeviceId
	set	@deviceId = null;

	--	get the next IP address
	select	top 1
			@address = ip
	from	@list
	where	ip > @address
	order by ip;

	--	retrieve or perform an nslookup on the IP Address...
	exec risk.Device_lookup	@address, @deviceId out;

	if isnull(@deviceId, 0) > 0
	begin
		update	risk.ScanDetail
		set		DeviceId	= @deviceId
			,	UpdatedBy	= null
			,	UpdatedOn	= null
		where	ScanId	= @ScanId
		and		IP		= @address;
	end;
end;

return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO