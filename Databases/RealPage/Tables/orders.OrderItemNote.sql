CREATE TABLE [orders].[OrderItemNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderItemIDSeq] [bigint] NULL,
[OrderItemTransactionIDSeq] [bigint] NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MandatoryFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItemNote_FootNote] DEFAULT ((0)),
[PrintOnInvoiceFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItemNote_PrintOnInvoiceFlag] DEFAULT ((1)),
[SortSeq] [bigint] NOT NULL CONSTRAINT [DF_OrderItemNote_SortSeq] DEFAULT ((99999)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_OrderItemNote_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_OrderItemNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_OrderItemNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderItemNote] ADD CONSTRAINT [PK_OrderItemNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_Orderitemnote_OrderIDSeq_OrderItemIDSeq] ON [orders].[OrderItemNote] ([OrderIDSeq] DESC, [OrderItemIDSeq] DESC, [OrderItemTransactionIDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderItemNote_RECORDSTAMP] ON [orders].[OrderItemNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderItemNote] WITH NOCHECK ADD CONSTRAINT [OrderItemNote_has_OrderIDSeq] FOREIGN KEY ([OrderIDSeq]) REFERENCES [orders].[Order] ([OrderIDSeq])
GO
ALTER TABLE [orders].[OrderItemNote] WITH NOCHECK ADD CONSTRAINT [OrderItemNote_has_OrderItemIDSeq] FOREIGN KEY ([OrderItemIDSeq]) REFERENCES [orders].[OrderItem] ([IDSeq])
GO
ALTER TABLE [orders].[OrderItemNote] WITH NOCHECK ADD CONSTRAINT [OrderItemNote_has_OrderItemTransactionIDSeq] FOREIGN KEY ([OrderItemTransactionIDSeq]) REFERENCES [orders].[OrderItemTransaction] ([IDSeq])
GO
