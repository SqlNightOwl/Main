CREATE TABLE [orders].[Order]
(
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AccountIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StatusCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApprovedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Order_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[ApprovedDate] [datetime] NOT NULL CONSTRAINT [DF_Order_ApprovedDate] DEFAULT (getdate()),
[RecordCRC] [numeric] (30, 0) NULL,
[Sieb77OrderID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SourceSystemName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SourceSystemOrderID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApprovedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Order_ApprovedByIDSeq] DEFAULT ((-1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Order_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Order_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[Order] ADD CONSTRAINT [PK_Order] PRIMARY KEY CLUSTERED  ([OrderIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_Order_AccountIDSeq] ON [orders].[Order] ([AccountIDSeq], [CompanyIDSeq], [PropertyIDSeq]) INCLUDE ([ApprovedByIDSeq], [ApprovedDate], [CreatedByIDSeq], [CreatedDate], [ModifiedByIDSeq], [ModifiedDate], [OrderIDSeq], [QuoteIDSeq], [StatusCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [OrderKeyStatusDate] ON [orders].[Order] ([AccountIDSeq], [CompanyIDSeq], [PropertyIDSeq], [QuoteIDSeq], [StatusCode], [CreatedDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_CreatedDate] ON [orders].[Order] ([CreatedDate], [ModifiedDate], [ApprovedDate]) INCLUDE ([AccountIDSeq], [ApprovedByIDSeq], [CompanyIDSeq], [CreatedByIDSeq], [ModifiedByIDSeq], [OrderIDSeq], [PropertyIDSeq], [QuoteIDSeq], [StatusCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_Order_QuoteID] ON [orders].[Order] ([QuoteIDSeq] DESC) INCLUDE ([AccountIDSeq], [ApprovedByIDSeq], [ApprovedDate], [CompanyIDSeq], [CreatedByIDSeq], [CreatedDate], [ModifiedByIDSeq], [ModifiedDate], [OrderIDSeq], [PropertyIDSeq], [StatusCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Order_RECORDSTAMP] ON [orders].[Order] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[Order] WITH NOCHECK ADD CONSTRAINT [Order_has_OrderStatusType] FOREIGN KEY ([StatusCode]) REFERENCES [orders].[OrderStatusType] ([Code])
GO
