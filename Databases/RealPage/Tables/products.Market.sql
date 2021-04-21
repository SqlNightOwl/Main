CREATE TABLE [products].[Market]
(
[Code] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ShortName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[MarketDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MarketDisplaySortSeq] [int] NOT NULL CONSTRAINT [DF_Market_MarketDisplaySortSeq] DEFAULT ((99999)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Market_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Market_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Market_SystemLogDate] DEFAULT (getdate()),
[RecordStamp] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [products].[Market] ADD CONSTRAINT [PK_Market] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Market Code;  Primary Key', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID of User who Created the record', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'CreatedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Creation Date', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description describing Market', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'MarketDescription'
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID of User who modified the record', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'ModifiedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified Date', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'RecordStamp: Internal to SQL Server', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'RecordStamp'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ShortName describing Market', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'ShortName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'SystemLogDate gets Updated to SystemDate upon Insert,Update', 'SCHEMA', N'products', 'TABLE', N'Market', 'COLUMN', N'SystemLogDate'
GO
