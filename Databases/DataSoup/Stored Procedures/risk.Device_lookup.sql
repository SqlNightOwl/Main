use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Device_lookup]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[Device_lookup]
GO
setuser N'risk'
GO
CREATE procedure risk.Device_lookup
	@item		varchar(50)
,	@DeviceId	int			= null	output
,	@Device		varchar(50)	= null	output
,	@IPList		varchar(99)	= null	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/29/2009
Purpose  :	Performs the NSLookup function for the item provided (name or IP) and
			returns the values assigned to the value.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		varchar(60)
,	@results	int;

declare	@lookup table
	(	record	varchar(90)	null
	,	row		tinyint	identity
	);

set	@results = @@error;

--	make user you have something to looup..
if isnull(rtrim(@item), '') = '' return -1;

--	attempt to retrieve the device based on the value provided...
select	@DeviceId	= d.DeviceId
	,	@Device		= d.Device
	,	@IPList		= isnull(@IPList, '') + i.IP + ';'
from	risk.Device		d
left join
		risk.DeviceIP	i
		on	d.DeviceId = i.DeviceId
where	d.Device	= @item
	or	i.IP		= @item;

--	exit if the device is found...
if isnull(@DeviceId, 0) = 0
begin
	--	the device wasn't found so look it up using NSLookup
	--	build and execute the bcp command, collect the results for error reporting/checking
	set	@cmd = 'nslookup ' + isnull(@item, '');
	insert @lookup exec @results = master.sys.xp_cmdshell @cmd;

	set @DeviceId	= 0;
	set @Device		= '';
	set	@IPList		= '';

	select	@Device = upper(ltrim(substring(left(Record, charindex('.', Record) - 1), 6, 50)))
	from	@lookup
	where	row		= 4
	and		record	like 'Name:%';

	select	@IPList = @IPList + ltrim(rtrim(substring(Record, 9, 25))) + ';'
	from	@lookup
	where	record	like 'Address:%'
	and		row		> 4;

	--	attempt to retrieve the DeviceId not that the particulars are known
	select	@DeviceId	= DeviceId
	from	risk.Device
	where	Device		= @Device;

	--	if the device isn found then return it...
	if @DeviceId > 0
	begin
		select	@Device		= d.Device
			,	@IPList		= isnull(@IPList, '') + i.IP + ';'
		from	risk.Device		d
		left join
				risk.DeviceIP	i
				on	d.DeviceId = i.DeviceId
		where	d.DeviceId	= @DeviceId;
	end;
	--	...otherwise add it to the tables if a Device Name or IP is returned...
	else if len(@Device + @IPList) > 0
	begin
		--	attempt to add the Device to the table...
		insert	risk.Device
			(	Device
			,	DeviceType
			,	AssignedTo
			)
		values
			(	@Device
			,	'UNKN'
			,	0
			);

		--	retrieve the results of the insert...
		select	@results	= @@error
			,	@DeviceId	= scope_identity()

		--	add the IP's associated with the device...
		if	@results = 0
		begin
			insert	risk.DeviceIP
				(	DeviceId
				,	IP
				)
			select	@DeviceId
				,	value
			from	tcu.fn_split(@IPList, ';');
		end;

	end;

end;

return @results;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [risk].[Device_lookup]  TO [wa_SecurityScan]
GO