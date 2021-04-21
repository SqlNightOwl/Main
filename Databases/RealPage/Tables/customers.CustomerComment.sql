CREATE TABLE [customers].[CustomerComment]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[CommentTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AccountTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CustomerComment_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CustomerComment_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[CustomerComment] ADD CONSTRAINT [PK_CustomerComment] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
ALTER TABLE [customers].[CustomerComment] WITH NOCHECK ADD CONSTRAINT [CustomerComment_has_AccountIDSeq] FOREIGN KEY ([AccountIDSeq]) REFERENCES [customers].[Account] ([IDSeq])
GO
ALTER TABLE [customers].[CustomerComment] WITH NOCHECK ADD CONSTRAINT [CustomerComment_has_AccountTypeCode] FOREIGN KEY ([AccountTypeCode]) REFERENCES [customers].[AccountType] ([Code])
GO
ALTER TABLE [customers].[CustomerComment] WITH NOCHECK ADD CONSTRAINT [CustomerComment_has_CommentTypeCode] FOREIGN KEY ([CommentTypeCode]) REFERENCES [customers].[CommentType] ([Code])
GO
ALTER TABLE [customers].[CustomerComment] WITH NOCHECK ADD CONSTRAINT [CustomerComment_has_CompanyIDSeq] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[CustomerComment] WITH NOCHECK ADD CONSTRAINT [CustomerComment_has_PropertyIDSeq] FOREIGN KEY ([PropertyIDSeq]) REFERENCES [customers].[Property] ([IDSeq])
GO
EXEC sp_addextendedproperty N'MS_Description', N'AccountIDSeq: Foreign key to IDSeq column in Account table', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'AccountIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'AccountTypeCode: Foreign key to code column in AccountType table. AHOFF for Company Level, APROP for Property Level', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'AccountTypeCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'CommentTypeCode: Foreign key to code column in CommentType table', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'CommentTypeCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'CompanyIDSeq: Foreign key to IDSeq column in Company table', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'CompanyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'User ID of Person Creating the record', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'CreatedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Created Date', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description of Customer Comments that is displayed on Read More option in UI', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'Description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'IDSeq: Primary Key and Auto Generated Identity value', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'User ID of Person Modifying the record', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'ModifiedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified Date', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Short Name of Customer Comments that is primarily displayed in UI', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PropertyIDSeq: Foreign key to IDSeq column in Property table', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'PropertyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Internal timestamp value', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'RECORDSTAMP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'System Log Datetime of Record Creation/Update', 'SCHEMA', N'customers', 'TABLE', N'CustomerComment', 'COLUMN', N'SystemLogDate'
GO
