CREATE TABLE [orders].[OrderItem]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderGroupIDSeq] [bigint] NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PublicationYear] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PublicationQuarter] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceVersion] [numeric] (18, 0) NULL,
[Units] [int] NULL,
[Beds] [int] NULL,
[PPUPercentage] [int] NULL,
[Quantity] [decimal] (18, 3) NOT NULL CONSTRAINT [DF_OrderItem_Quantity] DEFAULT ((1)),
[MinUnits] [int] NOT NULL CONSTRAINT [DF_Orderitem_MinUnits] DEFAULT ((0)),
[MaxUnits] [int] NOT NULL CONSTRAINT [DF_Orderitem_MaxUnits] DEFAULT ((0)),
[AllowProductCancelFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_AllowProductCancelFlag] DEFAULT ((1)),
[ChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_ChargeAmount] DEFAULT ((0)),
[EffectiveQuantity] [decimal] (18, 6) NOT NULL CONSTRAINT [DF_OrderItem_EffectiveQuantity] DEFAULT ((0.00)),
[ExtSOCChargeAmount] [money] NULL CONSTRAINT [DF_Orderitem_ExtSOCChargeAmount] DEFAULT ((0.00)),
[ExtChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_ExtChargeAmount] DEFAULT ((0)),
[DiscountPercent] [float] NOT NULL CONSTRAINT [DF_Orderitem_DiscountPercent] DEFAULT ((0)),
[DiscountAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_DiscountAmount] DEFAULT ((0)),
[NetUnitChargeamount] [money] NOT NULL CONSTRAINT [DF_OrderItem_NetUnitChargeamount] DEFAULT ((0.00)),
[NetChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_NetChargeAmount] DEFAULT ((0)),
[SiebelNetChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_SadeqaNetExtChargeAmount] DEFAULT ((0)),
[FinalSiebelNetChargeAmount] [money] NULL CONSTRAINT [DF_OrderItem_FinalSiebelNetChargeAmount] DEFAULT ((0)),
[ExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_ExtYear1ChargeAmount] DEFAULT ((0)),
[NetExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_NetExtYear1ChargeAmount] DEFAULT ((0)),
[ILFStartDate] [datetime] NULL,
[ILFEndDate] [datetime] NULL,
[ActivationStartDate] [datetime] NULL,
[ActivationEndDate] [datetime] NULL,
[ScreeningActivatedFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_ScreeningActivateFlag] DEFAULT ((0)),
[ExpirationDate] [datetime] NULL,
[StatusCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Orderitem_statuscode] DEFAULT ('FULF'),
[StartDate] [datetime] NULL,
[EndDate] [datetime] NULL,
[LastBillingPeriodFromDate] [datetime] NULL,
[LastBillingPeriodToDate] [datetime] NULL,
[CapMaxUnitsFlag] [bit] NOT NULL CONSTRAINT [DF_CapMaxUnitsFlag] DEFAULT ((0)),
[DollarMinimum] [money] NOT NULL CONSTRAINT [DF_OrderItem_DollarMinimum] DEFAULT ((0)),
[DollarMaximum] [money] NOT NULL CONSTRAINT [DF_OrderItem_DollarMaximum] DEFAULT ((0)),
[TotalDiscountPercent] [float] NOT NULL CONSTRAINT [DF_Orderitem_TotalDiscountPercent] DEFAULT ((0)),
[TotalDiscountAmount] [money] NOT NULL CONSTRAINT [DF_TotalDiscountAmount] DEFAULT ((0)),
[RenewalTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_OrderItem_RenewalTypeCode] DEFAULT ('ARNW'),
[PrintedOnInvoiceFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_PrintedOnInvoiceFlag] DEFAULT ((0)),
[ShippingAndHandlingAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_ShippingAndHandlingAmount] DEFAULT ((0.00)),
[UnitOfMeasure] [decimal] (18, 5) NOT NULL CONSTRAINT [DF_OrderItem_UnitOfMeasure] DEFAULT ((0)),
[AttachmentFlag] [bit] NULL,
[CancelReasonCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CancelDate] [datetime] NULL,
[CancelByIDSeq] [bigint] NULL,
[CancelNotes] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RenewalReviewedFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_RenewalReviewedFlag] DEFAULT ((0)),
[DoNotInvoiceFlag] [bit] NULL CONSTRAINT [DF_OrderItem_DoNotInvoiceFlag] DEFAULT ((0)),
[CredtCardPricingPercentage] [numeric] (30, 3) NOT NULL CONSTRAINT [DF_OrderItem_CredtCardPricingPercentage] DEFAULT ((0.000)),
[BillToAddressTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CrossFireMaximumAllowableCallVolume] [bigint] NULL,
[ExcludeForBookingsFlag] [bit] NOT NULL CONSTRAINT [DF_Orders_OrderItem_ExcludeForBookingsFlag] DEFAULT ((0)),
[ReportingTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PricingTiers] [int] NOT NULL CONSTRAINT [DF_OrderItem_PricingTiers] DEFAULT ((1)),
[RenewalFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_RenewalFlag] DEFAULT ((0)),
[RenewalCount] [bigint] NOT NULL CONSTRAINT [DF_OrderItem_RenewalCount] DEFAULT ((0)),
[MasterOrderItemIDSeq] [bigint] NULL,
[RenewedFromOrderItemIDSeq] [bigint] NULL,
[RenewalChargeAmount] [money] NOT NULL CONSTRAINT [DF_OrderItem_RenewalChargeAmount] DEFAULT ((0.00)),
[RenewalUserOverrideFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_RenewalUserOverrideFlag] DEFAULT ((0)),
[RenewalAdjustedChargeAmount] [money] NULL,
[RenewalStartDate] [datetime] NULL,
[RenewedByUserIDSeq] [bigint] NULL,
[RenewalNotes] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[HistoryFlag] [bit] NOT NULL CONSTRAINT [DF_OrderItem_HistoryFlag] DEFAULT ((0)),
[HistoryDate] [datetime] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_OrderItem_CreatedDate] DEFAULT (getdate()),
[FirstActivationStartDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[MigratedFlag] [bit] NOT NULL CONSTRAINT [DF_Orderitem_MigratedFlag] DEFAULT ((0)),
[ModifiedDate] [datetime] NULL,
[ModifiedByUserIDSeq] [bigint] NULL,
[SourceAnnualNetChargeAmount] [money] NULL CONSTRAINT [DF__OrderItem__Sourc__5B5BC469] DEFAULT ((0)),
[SourceFinalNetChargeAmount] [money] NULL CONSTRAINT [DF__OrderItem__Sourc__5C4FE8A2] DEFAULT ((0)),
[RenewalReviewedDate] [datetime] NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_OrderItem_CreatedByIDSeq] DEFAULT ((-1)),
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_OrderItem_SystemLogDate] DEFAULT (getdate()),
[FulfilledDate] [datetime] NULL,
[FulfilledByIDSeq] [bigint] NULL,
[CancelActivityDate] [datetime] NULL,
[RollbackReasonCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RollbackByIDSeq] [bigint] NULL,
[RollbackDate] [datetime] NULL,
[POILastBillingPeriodFromDate] [datetime] NULL,
[POILastBillingPeriodToDate] [datetime] NULL,
[POIUnits] [int] NULL,
[POIBeds] [int] NULL,
[POIPPUPercentage] [int] NULL,
[BillToDeliveryOptionCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PrePaidFlag] [int] NOT NULL CONSTRAINT [DF_OrderItem_PrePaidFlag] DEFAULT ((0)),
[ExternalQuoteIIFlag] [int] NOT NULL CONSTRAINT [DF_OrderItem_ExternalQuoteIIFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderItem] ADD CONSTRAINT [PK_OrderItem] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_OrderItem_OrderID] ON [orders].[OrderItem] ([BillToAddressTypeCode], [BillToDeliveryOptionCode], [FamilyCode], [ProductCode], [StatusCode], [OrderIDSeq] DESC, [OrderGroupIDSeq] DESC, [IDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_Orderitem_Code] ON [orders].[OrderItem] ([ChargeTypeCode], [ReportingTypeCode], [MeasureCode], [FrequencyCode], [FamilyCode], [ProductCode], [StatusCode], [RenewalTypeCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_OrderItem_RenewedFromID] ON [orders].[OrderItem] ([MasterOrderItemIDSeq] DESC, [RenewedFromOrderItemIDSeq] DESC, [RenewalCount] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Orders_OrderItems] ON [orders].[OrderItem] ([OrderIDSeq] DESC, [OrderGroupIDSeq] DESC, [IDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderItem_RECORDSTAMP] ON [orders].[OrderItem] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderItem] WITH NOCHECK ADD CONSTRAINT [OrderItem_has_Order] FOREIGN KEY ([OrderIDSeq]) REFERENCES [orders].[Order] ([OrderIDSeq])
GO
ALTER TABLE [orders].[OrderItem] WITH NOCHECK ADD CONSTRAINT [OrderItem_has_OrderGroup] FOREIGN KEY ([OrderIDSeq], [OrderGroupIDSeq]) REFERENCES [orders].[OrderGroup] ([OrderIDSeq], [IDSeq])
GO
ALTER TABLE [orders].[OrderItem] WITH NOCHECK ADD CONSTRAINT [OrderItem_has_RenewalTypeCode] FOREIGN KEY ([RenewalTypeCode]) REFERENCES [orders].[RenewalType] ([Code])
GO
ALTER TABLE [orders].[OrderItem] WITH NOCHECK ADD CONSTRAINT [OrderItem_has_OrderStatusType] FOREIGN KEY ([StatusCode]) REFERENCES [orders].[OrderStatusType] ([Code])
GO
