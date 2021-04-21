CREATE TABLE [products].[ProductFootNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceVersion] [numeric] (18, 0) NOT NULL,
[FootNote] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DisabledFlag] [bit] NOT NULL CONSTRAINT [DF_ProductFootNote_DisabledFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ProductFootNote_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ProductFootNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ProductFootNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [products].[ProductFootNote] ADD CONSTRAINT [PK_ProductFootNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ProductFootNote_RECORDSTAMP] ON [products].[ProductFootNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[ProductFootNote] WITH NOCHECK ADD CONSTRAINT [ProductFootNote_has_Product] FOREIGN KEY ([ProductCode], [PriceVersion]) REFERENCES [products].[Product] ([Code], [PriceVersion])
GO
