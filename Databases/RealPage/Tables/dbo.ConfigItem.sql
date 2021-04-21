CREATE TABLE [dbo].[ConfigItem]
(
[ConfigItemId] [tinyint] NOT NULL IDENTITY(1, 1),
[ConfigItem] [sys].[sysname] NOT NULL,
[MinValue] [int] NOT NULL,
[MaxValue] [int] NOT NULL,
[DefaultValue] [int] NOT NULL,
[ConfigItemDescription] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ConfigItem] ADD CONSTRAINT [CK_ConfigItem_DefaultValue] CHECK (([DefaultValue]>=[MinValue] AND [DefaultValue]<=[MaxValue]))
GO
ALTER TABLE [dbo].[ConfigItem] ADD CONSTRAINT [PK_ConfigItem] PRIMARY KEY CLUSTERED  ([ConfigItemId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_ConfigItem] ON [dbo].[ConfigItem] ([ConfigItem]) INCLUDE ([DefaultValue]) ON [PRIMARY]
GO
