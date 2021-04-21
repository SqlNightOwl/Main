CREATE TABLE [orders].[OrderItemTransaction]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[OrderItemIDSeq] [bigint] NOT NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderGroupIDSeq] [bigint] NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceVersion] [numeric] (18, 0) NOT NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ServiceCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TransactionItemName] [varchar] (300) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ExtChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItemTransaction_ExtChargeAmount] DEFAULT ((0)),
[DiscountAmount] [money] NOT NULL CONSTRAINT [DF_OrderItemTransaction_DiscountAmount] DEFAULT ((0)),
[NetChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItemTransaction_NetChargeAmount] DEFAULT ((0)),
[TransactionalFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItemTransaction_TransactionalFlag] DEFAULT ((0)),
[InvoicedFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItemTransaction_InvoicedFlag] DEFAULT ((0)),
[SourceTransactionID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ServiceDate] [datetime] NOT NULL CONSTRAINT [DF_OrderItemTransaction_ReportDate] DEFAULT (getdate()),
[Quantity] [decimal] (18, 3) NOT NULL CONSTRAINT [DF_OrderItemTransaction_Quantity] DEFAULT ((0)),
[TransactionImportIDSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[ImportSource] [varchar] (250) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProcessedMonthEnd] [datetime] NULL,
[ImportDate] [datetime] NULL,
[PrintedOnInvoiceFlag] [bit] NOT NULL CONSTRAINT [DF_OrderitemTransaction_PrintedOnInvoiceFlag] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_OrderitemTransaction_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_OrderitemTransaction_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_OrderitemTransaction_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderItemTransaction] ADD CONSTRAINT [PK_OrderItemTransaction] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderIDSeq_OrderItemIDSeq] ON [orders].[OrderItemTransaction] ([OrderIDSeq], [OrderGroupIDSeq], [OrderItemIDSeq], [ServiceDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderItemTransaction_TransactionImportIDSeq] ON [orders].[OrderItemTransaction] ([TransactionImportIDSeq], [OrderItemIDSeq]) INCLUDE ([IDSeq], [ImportSource], [NetChargeAmount], [OrderGroupIDSeq], [OrderIDSeq], [ProductCode], [Quantity], [ServiceDate], [SourceTransactionID], [TransactionItemName]) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderItemTransaction] WITH NOCHECK ADD CONSTRAINT [OrderItemTransaction_has_OrderItem] FOREIGN KEY ([OrderItemIDSeq]) REFERENCES [orders].[OrderItem] ([IDSeq])
GO
