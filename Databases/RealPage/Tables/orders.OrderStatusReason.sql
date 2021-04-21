CREATE TABLE [orders].[OrderStatusReason]
(
[Code] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderStatusTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderStatusReason] ADD CONSTRAINT [PK_OrderStatusReason] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderStatusReason_RECORDSTAMP] ON [orders].[OrderStatusReason] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderStatusReason] WITH NOCHECK ADD CONSTRAINT [OrderStatusReason_has_OrderStatusType] FOREIGN KEY ([OrderStatusTypeCode]) REFERENCES [orders].[OrderStatusType] ([Code])
GO
