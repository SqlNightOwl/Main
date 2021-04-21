CREATE TABLE [dbo].[ServerConfig]
(
[MonitoredServerId] [smallint] NOT NULL,
[ConfigItemId] [tinyint] NOT NULL,
[ConfigValue] [int] NOT NULL,
[RunningValue] [int] NOT NULL,
[CreatedBy] [sys].[sysname] NOT NULL CONSTRAINT [DF_ServerConfig_CreatedBy] DEFAULT (suser_sname()),
[CreatedOn] [datetime] NOT NULL CONSTRAINT [DF_ServerConfig_CreatedOn] DEFAULT (getdate()),
[UpdatedBy] [sys].[sysname] NULL,
[UpdatedOn] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger dbo.ServerConfig_tiu
on dbo.ServerConfig
for insert, update
as
begin
	set nocount on;
	declare
		@now		datetime = getdate()
	,	@userName	sysname	 = suser_sname()

	if update(CreatedBy)
	or update(CreatedOn)
	begin
		update	o
		set		CreatedBy = d.CreatedBy
			,	CreatedOn = d.CreatedOn
			,	UpdatedBy = d.UpdatedBy
			,	UpdatedOn = d.UpdatedOn
		from	dbo.ServerConfig	o
		join	deleted				d
				on	o.MonitoredServerId = d.MonitoredServerId
				and	o.ConfigItemId		= d.ConfigItemId;
	end;
	if not(	update(UpdatedBy) or
			update(UpdatedOn) )
	begin
		update	o
		set		UpdatedBy = @userName
			,	UpdatedOn = @now
		from	dbo.ServerConfig	o
		join	inserted			i
				on	i.MonitoredServerId = o.MonitoredServerId
				and	i.ConfigItemId		= o.ConfigItemId;
	end;
end;
GO
ALTER TABLE [dbo].[ServerConfig] ADD CONSTRAINT [PK_ServerConfig] PRIMARY KEY CLUSTERED  ([MonitoredServerId], [ConfigItemId]) ON [PRIMARY]
GO
