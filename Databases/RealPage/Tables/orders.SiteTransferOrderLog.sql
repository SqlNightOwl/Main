CREATE TABLE [orders].[SiteTransferOrderLog]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[FromOrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FromCompanyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FromPropertyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FromQuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ToCompanyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ToPropertyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ToQuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FromOrderStatusCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FromOrderItemIDSeq] [bigint] NOT NULL,
[FromOrderItemStatusCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TOCreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteTransferOrderLog_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [orders].[SiteTransferOrderLog] ADD CONSTRAINT [PK_SiteTransferOrderLog] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_SiteTransferOrderLog_RECORDSTAMP] ON [orders].[SiteTransferOrderLog] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[SiteTransferOrderLog] WITH NOCHECK ADD CONSTRAINT [SiteTransferOrderLog_has_FromOrderIDSeq] FOREIGN KEY ([FromOrderIDSeq]) REFERENCES [orders].[Order] ([OrderIDSeq])
GO
ALTER TABLE [orders].[SiteTransferOrderLog] WITH NOCHECK ADD CONSTRAINT [SiteTransferOrderLog_has_FromOrderItemIDSeq] FOREIGN KEY ([FromOrderItemIDSeq]) REFERENCES [orders].[OrderItem] ([IDSeq])
GO
ALTER TABLE [orders].[SiteTransferOrderLog] WITH NOCHECK ADD CONSTRAINT [SiteTransferOrderLog_has_FromOrderItemStatusCode] FOREIGN KEY ([FromOrderItemStatusCode]) REFERENCES [orders].[OrderStatusType] ([Code])
GO
ALTER TABLE [orders].[SiteTransferOrderLog] WITH NOCHECK ADD CONSTRAINT [SiteTransferOrderLog_has_FromOrderStatusCode] FOREIGN KEY ([FromOrderStatusCode]) REFERENCES [orders].[OrderStatusType] ([Code])
GO
