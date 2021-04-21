CREATE TABLE [customers].[CommentType]
(
[Code] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DisabledFlag] [bit] NOT NULL CONSTRAINT [DF_CommentType_DisabledFlag] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CommentType_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CommentType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[CommentType] ADD CONSTRAINT [PK_CommentType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'CommentType code: Primay Key', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'User ID of Person Creating the record', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'CreatedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Created Date', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description for CommentType Code', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'Description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'DisabledFlag: 0 means active record for display in UI drop down,1 means Inactive and Disabled', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'DisabledFlag'
GO
EXEC sp_addextendedproperty N'MS_Description', N'User ID of Person Modifying the record', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'ModifiedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified Date', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Short Name for CommentType Code', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Internal timestamp value', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'RECORDSTAMP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'System Log Datetime of Record Creation/Update', 'SCHEMA', N'customers', 'TABLE', N'CommentType', 'COLUMN', N'SystemLogDate'
GO
