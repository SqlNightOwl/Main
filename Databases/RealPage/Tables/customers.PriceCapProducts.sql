CREATE TABLE [customers].[PriceCapProducts]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProducts_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapProducts_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProducts_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapProducts] ADD CONSTRAINT [PK_PriceCapProducts] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCapProducts_RECORDSTAMP] ON [customers].[PriceCapProducts] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapProducts] WITH NOCHECK ADD CONSTRAINT [PriceCapProducts_has_PriceCap] FOREIGN KEY ([PriceCapIDSeq]) REFERENCES [customers].[PriceCap] ([IDSeq])
GO
