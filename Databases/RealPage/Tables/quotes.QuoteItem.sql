CREATE TABLE [quotes].[QuoteItem]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[GroupIDSeq] [bigint] NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PublicationYear] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PublicationQuarter] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PreConfiguredBundleCode] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PreConfiguredBundleFlag] [bit] NOT NULL CONSTRAINT [DF_QuoteItem_PreConfiguredBundleFlag] DEFAULT ((0)),
[AllowProductCancelFlag] [bit] NOT NULL CONSTRAINT [DF_QuoteItem_AllowProductCancelFlag] DEFAULT ((1)),
[PriceVersion] [numeric] (18, 0) NULL,
[Sites] [int] NOT NULL CONSTRAINT [DF_QuoteItem_Sites_1] DEFAULT ((0)),
[Units] [int] NOT NULL CONSTRAINT [DF_QuoteItem_Units_1] DEFAULT ((0)),
[Beds] [int] NOT NULL CONSTRAINT [DF_QuoteItem_Beds] DEFAULT ((0)),
[PPUPercentage] [int] NOT NULL CONSTRAINT [DF_QuoteItem_PPUPercentage] DEFAULT ((100)),
[Quantity] [decimal] (18, 3) NOT NULL CONSTRAINT [DF_QuoteItem_Quantity] DEFAULT ((1)),
[MinUnits] [int] NOT NULL CONSTRAINT [DF_Quoteitem_MinUnits] DEFAULT ((0)),
[MaxUnits] [int] NOT NULL CONSTRAINT [DF_Quoteitem_MaxUnits] DEFAULT ((0)),
[Multiplier] [decimal] (18, 5) NOT NULL CONSTRAINT [DF_QuoteItem_Multiplier] DEFAULT ((1)),
[QuantityEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_QuoteItem_QuantityEnabledFlag] DEFAULT ((0)),
[ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_ChargeAmount] DEFAULT ((0)),
[ExtChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_ExtChargeAmount] DEFAULT ((0)),
[ExtSOCChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quoteitem_ExtSOCChargeAmount] DEFAULT ((0)),
[ExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_ExtYearChargeAmount] DEFAULT ((0)),
[ExtYear2ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_ExtYear2ChargeAmount] DEFAULT ((0)),
[ExtYear3ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_ExtYear3ChargeAmount] DEFAULT ((0)),
[DiscountPercent] [float] NOT NULL CONSTRAINT [DF_QuoteItem_DiscountPercent] DEFAULT ((0)),
[DiscountAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_DiscountAmount] DEFAULT ((0)),
[TotalDiscountPercent] [float] NOT NULL CONSTRAINT [DF_QuoteItem_TotalDiscountPercent] DEFAULT ((0)),
[TotalDiscountAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_TotalDiscountAmount] DEFAULT ((0)),
[NetChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_NetChargeAmount] DEFAULT ((0)),
[NetExtChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_NetExtChargeAmount] DEFAULT ((0)),
[NetExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_NetExtYearChargeAmount] DEFAULT ((0)),
[NetExtYear2ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_NetExtYear1ChargeAmount] DEFAULT ((0)),
[NetExtYear3ChargeAmount] [money] NOT NULL CONSTRAINT [DF_QuoteItem_NetExtYear3ChargeAmount] DEFAULT ((0)),
[CapMaxUnitsFlag] [bit] NOT NULL CONSTRAINT [DF_CapMaxUnitsFlag] DEFAULT ((0)),
[DollarMinimum] [money] NOT NULL CONSTRAINT [DF_QuoteItem_DollarMinimum] DEFAULT ((0)),
[DollarMaximum] [money] NOT NULL CONSTRAINT [DF_QuoteItem_DollarMaximum] DEFAULT ((0)),
[UnitOfMeasure] [decimal] (18, 5) NOT NULL CONSTRAINT [DF_Quoteitem_UnitOfMeasure] DEFAULT ((0)),
[CCTransactionPercent] [decimal] (5, 3) NOT NULL CONSTRAINT [DF_QuoteItem_CCTransactionFee] DEFAULT ((0)),
[CredtCardPricingPercentage] [numeric] (30, 3) NOT NULL CONSTRAINT [DF_Quoteitem_CredtCardPricingPercentage] DEFAULT ((0.000)),
[ExcludeForBookingsFlag] [bit] NOT NULL CONSTRAINT [DF_Quotes_Quoteitem_ExcludeForBookingsFlag] DEFAULT ((0)),
[CrossFireMaximumAllowableCallVolume] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteItem_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QuoteItem_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteItem_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteItem] ADD CONSTRAINT [PK_QuoteItem] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_Quoteitem_ProductCode] ON [quotes].[QuoteItem] ([ProductCode], [MeasureCode], [FrequencyCode]) INCLUDE ([AllowProductCancelFlag], [Beds], [CapMaxUnitsFlag], [ChargeAmount], [ChargeTypeCode], [CredtCardPricingPercentage], [CrossFireMaximumAllowableCallVolume], [DiscountAmount], [DiscountPercent], [DollarMaximum], [DollarMinimum], [ExcludeForBookingsFlag], [ExtChargeAmount], [ExtYear1ChargeAmount], [ExtYear2ChargeAmount], [ExtYear3ChargeAmount], [FamilyCode], [GroupIDSeq], [IDSeq], [MaxUnits], [MinUnits], [Multiplier], [NetChargeAmount], [NetExtChargeAmount], [NetExtYear1ChargeAmount], [NetExtYear2ChargeAmount], [NetExtYear3ChargeAmount], [PPUPercentage], [PriceVersion], [PublicationQuarter], [PublicationYear], [Quantity], [QuantityEnabledFlag], [QuoteIDSeq], [Sites], [TotalDiscountAmount], [TotalDiscountPercent], [UnitOfMeasure], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_Quoteitem_QuoteIDseq] ON [quotes].[QuoteItem] ([QuoteIDSeq], [GroupIDSeq], [ProductCode]) INCLUDE ([AllowProductCancelFlag], [Beds], [CapMaxUnitsFlag], [ChargeAmount], [ChargeTypeCode], [CredtCardPricingPercentage], [CrossFireMaximumAllowableCallVolume], [DiscountAmount], [DiscountPercent], [DollarMaximum], [DollarMinimum], [ExcludeForBookingsFlag], [ExtChargeAmount], [ExtYear1ChargeAmount], [ExtYear2ChargeAmount], [ExtYear3ChargeAmount], [FamilyCode], [FrequencyCode], [IDSeq], [MaxUnits], [MeasureCode], [MinUnits], [Multiplier], [NetChargeAmount], [NetExtChargeAmount], [NetExtYear1ChargeAmount], [NetExtYear2ChargeAmount], [NetExtYear3ChargeAmount], [PPUPercentage], [PriceVersion], [PublicationQuarter], [PublicationYear], [Quantity], [QuantityEnabledFlag], [Sites], [TotalDiscountAmount], [TotalDiscountPercent], [UnitOfMeasure], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QuoteItem_RECORDSTAMP] ON [quotes].[QuoteItem] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteItem] WITH NOCHECK ADD CONSTRAINT [QuoteItem_has_Quote] FOREIGN KEY ([QuoteIDSeq]) REFERENCES [quotes].[Quote] ([QuoteIDSeq])
GO
ALTER TABLE [quotes].[QuoteItem] WITH NOCHECK ADD CONSTRAINT [QuoteItem_has_Group] FOREIGN KEY ([QuoteIDSeq], [GroupIDSeq]) REFERENCES [quotes].[Group] ([QuoteIDSeq], [IDSeq])
GO
