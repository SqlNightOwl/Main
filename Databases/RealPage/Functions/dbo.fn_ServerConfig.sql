SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function dbo.fn_ServerConfig
(	@MonitoredServer sysname
,	@ConfigItem		 sysname
)
returns table
as
return(	select	ms.MonitoredServer
			,	ci.ConfigItem
			,	ci.MinValue
			,	ci.MaxValue
			,	ci.DefaultValue
			,	sc.ConfigValue
			,	sc.RunningValue
			,	case
				when sc.ConfigValue  = ci.DefaultValue
				 and sc.RunningValue = ci.DefaultValue then 0
				else 1 end	as IsChangedFromDefault
			,	case sc.ConfigValue
				when sc.RunningValue then 0
				else 1 end	as IsChangedAfterRestart
			,	ci.ConfigItemDescription
		from	dbo.ServerConfig	sc
		join	dbo.ConfigItem		ci
				on	ci.ConfigItemId	= sc.ConfigItemId
				and(ci.ConfigItem	= @ConfigItem or @ConfigItem is null )
		join	dbo.MonitoredServer	ms
				on	ms.MonitoredServerId = sc.MonitoredServerId
				and(ms.MonitoredServer	 = @MonitoredServer or @MonitoredServer is null ) );
GO
