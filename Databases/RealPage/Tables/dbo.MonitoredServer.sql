CREATE TABLE [dbo].[MonitoredServer]
(
[MonitoredServerId] [smallint] NOT NULL IDENTITY(-32768, 1),
[MonitoredServer] [sys].[sysname] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MonitoredServer] ADD CONSTRAINT [PK_MonitoredServer] PRIMARY KEY CLUSTERED  ([MonitoredServerId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_MonitoredServer] ON [dbo].[MonitoredServer] ([MonitoredServer]) ON [PRIMARY]
GO
