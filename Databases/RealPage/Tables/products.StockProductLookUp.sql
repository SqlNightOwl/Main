CREATE TABLE [products].[StockProductLookUp]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[StockProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[StockProductPriceVersion] [numeric] (18, 0) NOT NULL CONSTRAINT [DF__StockProd__Stock__16B953FD] DEFAULT ((100)),
[AssociatedProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AssociatedProductPriceVersion] [numeric] (18, 0) NOT NULL CONSTRAINT [DF__StockProd__Assoc__17AD7836] DEFAULT ((100)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_StockProductLookUp_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_StockProductLookUp_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_StockProductLookUp_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[StockProductLookUp] ADD CONSTRAINT [PK_StockProductLookUp] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_StockProductLookUp_RECORDSTAMP] ON [products].[StockProductLookUp] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[StockProductLookUp] WITH NOCHECK ADD CONSTRAINT [ProductInvalidCombo_has_AssociatedProductCode] FOREIGN KEY ([AssociatedProductCode], [AssociatedProductPriceVersion]) REFERENCES [products].[Product] ([Code], [PriceVersion])
GO
ALTER TABLE [products].[StockProductLookUp] WITH NOCHECK ADD CONSTRAINT [StockProductLookUp_has_StockProductCode] FOREIGN KEY ([StockProductCode], [StockProductPriceVersion]) REFERENCES [products].[Product] ([Code], [PriceVersion])
GO
