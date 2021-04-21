SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure dbo.ServerConfig_sav
	@MonitoredServer	sysname	= null
as

set nocount on;

declare
	@sqlCmd		nvarchar(1000)
,	@serverId	smallint

if object_id(N'tempdb.dbo.#tempServerConfig', N'U') is not null
	drop table #tempServerConfig;

create table #tempServerConfig
	(	ConfigItem		sysname primary key
	,	MinValue		int
	,	MaxValue		int
	,	ConfigValue		int
	,	RunningValue	int
	);

--	make sure there is a value for the MonitoredServer
set @MonitoredServer = isnull(nullif(@MonitoredServer, ''), @@servername);

--	if not there, add this server to the list of monitored server
if not exists (	select	1 from dbo.MonitoredServer
				where	MonitoredServer = @MonitoredServer )
	insert	dbo.MonitoredServer
	select	@MonitoredServer;

--	retrieve MonitoredServerId
select	@serverId = MonitoredServerId
from	dbo.MonitoredServer
where	MonitoredServer = @MonitoredServer

--	load the table with the server config values
set	@sqlCmd = 'insert #tempServerConfig exec [' + @MonitoredServer + '].master.sys.sp_configure;'
exec sys.sp_executesql @sqlCmd;

--	NOTE:	the	trigger on the ConfigItem table handles history autiting

--	first, try updating the existing values
update	sc
set		ConfigValue	 = cv.ConfigValue
	,	RunningValue = cv.RunningValue
	,	UpdatedBy	 = suser_sname()
	,	UpdatedOn	 = getdate()
from	#tempServerConfig	cv
join	dbo.ConfigItem		ci
		on	cv.ConfigItem = ci.ConfigItem
join	dbo.ServerConfig	sc
		on	ci.ConfigItemId = sc.ConfigItemId
join	dbo.MonitoredServer	ms
		on	sc.MonitoredServerId = ms.MonitoredServerId
		and	@serverId			 = ms.MonitoredServerId
where	sc.ConfigValue	!= cv.ConfigValue
	or	sc.RunningValue	!= cv.RunningValue;

--	determine if any rows were affected or an error occured
if	@@rowcount	= 0
and	@@error		= 0
begin
	--	nothing happened, so insert the baseline values for the server
	insert	dbo.ServerConfig
		(	MonitoredServerId
		,	ConfigItemId
		,	ConfigValue
		,	RunningValue
		,	CreatedBy
		,	CreatedOn
		)
	select	@serverId
		,	ci.ConfigItemId
		,	cv.ConfigValue
		,	cv.RunningValue
		,	suser_sname()
		,	getdate()
	from	#tempServerConfig	cv
	join	dbo.ConfigItem		ci
			on	cv.ConfigItem = ci.ConfigItem;
end;
GO
