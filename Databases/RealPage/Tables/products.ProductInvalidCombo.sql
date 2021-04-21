CREATE TABLE [products].[ProductInvalidCombo]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[FirstProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FirstProductPriceVersion] [numeric] (18, 0) NOT NULL CONSTRAINT [DF__ProductIn__First__100C566E] DEFAULT ((100)),
[SecondProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SecondProductPriceVersion] [numeric] (18, 0) NOT NULL CONSTRAINT [DF__ProductIn__Secon__11007AA7] DEFAULT ((100)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ProductInvalidCombo_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ProductInvalidCombo_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ProductInvalidCombo_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[ProductInvalidCombo] ADD CONSTRAINT [PK_InvalidCombination] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_ProductInvalidCombo_Charge_FirstProductcode] ON [products].[ProductInvalidCombo] ([FirstProductCode], [FirstProductPriceVersion]) INCLUDE ([SecondProductCode], [SecondProductPriceVersion]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ProductInvalidCombo_RECORDSTAMP] ON [products].[ProductInvalidCombo] ([RECORDSTAMP]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_ProductInvalidCombo_Charge_SecondProductcode] ON [products].[ProductInvalidCombo] ([SecondProductCode], [SecondProductPriceVersion]) INCLUDE ([FirstProductCode], [FirstProductPriceVersion]) ON [PRIMARY]
GO
ALTER TABLE [products].[ProductInvalidCombo] WITH NOCHECK ADD CONSTRAINT [ProductInvalidCombo_has_FirstProductCode] FOREIGN KEY ([FirstProductCode], [FirstProductPriceVersion]) REFERENCES [products].[Product] ([Code], [PriceVersion])
GO
ALTER TABLE [products].[ProductInvalidCombo] WITH NOCHECK ADD CONSTRAINT [ProductInvalidCombo_has_SecondProductCode] FOREIGN KEY ([SecondProductCode], [SecondProductPriceVersion]) REFERENCES [products].[Product] ([Code], [PriceVersion])
GO
