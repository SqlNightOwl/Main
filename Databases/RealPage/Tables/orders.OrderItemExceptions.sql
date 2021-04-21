CREATE TABLE [orders].[OrderItemExceptions]
(
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderGroupIDSeq] [bigint] NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceVersion] [numeric] (18, 0) NULL,
[Quantity] [int] NULL,
[AllowProductCancelFlag] [bit] NULL,
[ChargeAmount] [money] NULL,
[ExtChargeAmount] [money] NULL,
[DiscountPercent] [float] NULL,
[DiscountAmount] [money] NULL,
[NetChargeAmount] [money] NULL,
[SiebelNetChargeAmount] [money] NULL,
[ILFStartDate] [datetime] NULL,
[ILFEndDate] [datetime] NULL,
[ActivationStartDate] [datetime] NULL,
[ActivationEndDate] [datetime] NULL,
[ScreeningActivatedFlag] [bit] NULL,
[ExpirationDate] [datetime] NULL,
[StatusCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StartDate] [datetime] NULL,
[EndDate] [datetime] NULL,
[FinalSiebelNetChargeAmount] [money] NULL,
[OrderItemRowID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SiebelRowID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderItemExceptions_RECORDSTAMP] ON [orders].[OrderItemExceptions] ([RECORDSTAMP]) ON [PRIMARY]
GO
