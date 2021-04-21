CREATE TABLE [customers].[PriceCapProductsHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[LogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProductsHistory_LogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProductsHistory_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapProductsHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProductsHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapProductsHistory] ADD CONSTRAINT [PK_PriceCapProductsHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCapProductsHistory_RECORDSTAMP] ON [customers].[PriceCapProductsHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
