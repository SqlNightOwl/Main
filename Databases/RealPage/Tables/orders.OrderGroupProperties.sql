CREATE TABLE [orders].[OrderGroupProperties]
(
[AccountIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderGroupIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceTypeCode] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL CONSTRAINT [DF_OrderGroupProperties_PriceTypeCode] DEFAULT ('Normal'),
[ThresholdOverrideFlag] [bit] NULL CONSTRAINT [DF_OrderGroupProperties_ThresholdOverrideFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_OrderGroupProperties_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_OrderGroupProperties_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_OrderGroupProperties_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderGroupProperties] ADD CONSTRAINT [PK_OrderGroupProperties_1] PRIMARY KEY CLUSTERED  ([AccountIDSeq], [OrderIDSeq], [OrderGroupIDSeq], [CompanyIDSeq], [PropertyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_OrderGroupProperties_OrderGroupIDSeq] ON [orders].[OrderGroupProperties] ([OrderGroupIDSeq], [OrderIDSeq], [AccountIDSeq], [CompanyIDSeq]) INCLUDE ([PriceTypeCode], [PropertyIDSeq], [ThresholdOverrideFlag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderGroupProperties_RECORDSTAMP] ON [orders].[OrderGroupProperties] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderGroupProperties] WITH NOCHECK ADD CONSTRAINT [OrderGroupProperties_has_OrderGroup] FOREIGN KEY ([OrderIDSeq], [OrderGroupIDSeq]) REFERENCES [orders].[OrderGroup] ([OrderIDSeq], [IDSeq])
GO
