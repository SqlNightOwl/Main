CREATE TABLE [customers].[PriceCapNoteHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapNoteIDSeq] [bigint] NOT NULL,
[PriceCapIDSeq] [bigint] NOT NULL,
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedByID] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapNoteHistory_CreatedDate] DEFAULT (getdate()),
[ModifiedByID] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[LogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapNoteHistory_LogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapNoteHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapNoteHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapNoteHistory] ADD CONSTRAINT [PK_PriceCapNoteHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID Seq of User Created the PriceCapNoteHistory Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNoteHistory', 'COLUMN', N'CreatedByID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Created date of PriceCapNoteHistory Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNoteHistory', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Uniqueidentifier for PriceCapNoteHistory. Primary Key', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNoteHistory', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID Seq of User Modified the PriceCapNoteHistory Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNoteHistory', 'COLUMN', N'ModifiedByID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Modified date of PriceCapNoteHistory Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNoteHistory', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PriceCapIDSeq of related PriceCap. Foreign Key to PriceCap Table', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNoteHistory', 'COLUMN', N'PriceCapIDSeq'
GO
