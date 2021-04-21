CREATE TABLE [customers].[PriceCapNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapIDSeq] [bigint] NOT NULL,
[Description] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedByID] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapNote_CreatedDate] DEFAULT (getdate()),
[ModifiedByID] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapNote] ADD CONSTRAINT [PK_PriceCapNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapNote] WITH NOCHECK ADD CONSTRAINT [PriceCapNote_has_PriceCap] FOREIGN KEY ([PriceCapIDSeq]) REFERENCES [customers].[PriceCap] ([IDSeq])
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID Seq of User Created the PriceCapNote Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNote', 'COLUMN', N'CreatedByID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Created date of PriceCapNote Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNote', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Uniqueidentifier for PriceCapNote. Primary Key', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNote', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID Seq of User Modified the PriceCapNote Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNote', 'COLUMN', N'ModifiedByID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Modified date of PriceCapNote Record', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNote', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PriceCapIDSeq of related PriceCap. Foreign Key to PriceCap Table', 'SCHEMA', N'customers', 'TABLE', N'PriceCapNote', 'COLUMN', N'PriceCapIDSeq'
GO
