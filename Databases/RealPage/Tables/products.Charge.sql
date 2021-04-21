CREATE TABLE [products].[Charge]
(
[ChargeIDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceVersion] [numeric] (18, 0) NOT NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SiebelProductID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ChargeAmount] [money] NOT NULL CONSTRAINT [DF_ProductPricing_ItemCharge] DEFAULT ((0)),
[MinUnits] [int] NOT NULL CONSTRAINT [DF_ProductPricing_MinUnits] DEFAULT ((30)),
[MaxUnits] [int] NOT NULL CONSTRAINT [DF_ProductPricing_MaxUnits] DEFAULT ((500)),
[UnitBasis] [decimal] (18, 5) NOT NULL CONSTRAINT [DF_Charge_UnitBasis] DEFAULT ((1)),
[FlatPriceFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_FlatPriceFlag] DEFAULT ((0)),
[DollarMinimum] [money] NOT NULL CONSTRAINT [DF_Charge_DollarMinimum] DEFAULT ((0)),
[DollarMinimumEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_DollarMinMaxEnabledFlag] DEFAULT ((0)),
[DollarMaximum] [money] NOT NULL CONSTRAINT [DF_Charge_DollarMaximum] DEFAULT ((0)),
[DollarMaximumEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_DollarMaximumEnabledFlag] DEFAULT ((0)),
[MinThresholdOverride] [bit] NOT NULL CONSTRAINT [DF_ProductPricing_ThresholdOverride] DEFAULT ((0)),
[MaxThresholdOverride] [bit] NOT NULL CONSTRAINT [DF_ProductPricing_MaxThresholdOverride] DEFAULT ((0)),
[DiscountMaxPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_ProductPricing_DiscountMaxPercent] DEFAULT ((0.00)),
[CommissionMaxPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_ProductPricing_CommissionMaxPercent] DEFAULT ((0.00)),
[QuantityEnabledFlag] [int] NOT NULL CONSTRAINT [DF_Charge_QuantityEnabledFlag] DEFAULT ((0)),
[QuantityMultiplierFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_QuantityMultiplierBit] DEFAULT ((0)),
[PriceByPPUPercentageEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_PriceByPPUPercentageEnabledFlag] DEFAULT ((0)),
[PriceByBedEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_PriceByBedEnabledFlag] DEFAULT ((0)),
[DisplayType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Charge_DisplayType] DEFAULT ('SITE'),
[DisabledFlag] [bit] NOT NULL CONSTRAINT [DF_ProductMaster_DisabledFlag] DEFAULT ((0)),
[StartDate] [datetime] NOT NULL,
[EndDate] [datetime] NULL,
[CreatedBy] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Charge_CreateDate] DEFAULT (getdate()),
[ModifyDate] [datetime] NULL CONSTRAINT [DF_Charge_ModifyDate] DEFAULT (getdate()),
[RevenueTierCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RevenueAccountCode] [varchar] (32) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DeferredRevenueAccountCode] [varchar] (32) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[TaxwareCode] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RevenueRecognitionCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF__Charge__RevenueR__2665ABE1] DEFAULT ('SRR'),
[SRSDisplayQuantityFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_SRSDisplayQuantityFlag] DEFAULT ((1)),
[CreditCardPercentageEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_charge_CreditCardPercentageEnabledFlag] DEFAULT ((0)),
[CredtCardPricingPercentage] [numeric] (30, 3) NOT NULL CONSTRAINT [DF_charge_CredtCardPricingPercentage] DEFAULT ((0.000)),
[ReportingTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SeparateInvoiceGroupNumber] [bigint] NOT NULL CONSTRAINT [DF_Charge_SeparateInvoiceGroupNumber] DEFAULT ((0)),
[ExplodeQuantityatOrderFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_ExplodeQuantityatOrderFlag] DEFAULT ((1)),
[MarkAsPrintedFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_MarkAsPrintedFlag] DEFAULT ((0)),
[CrossFireCallPricingEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_CrossFireCallPricingEnabledFlag] DEFAULT ((0)),
[MPFPublicationName] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportCategoryName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportSubcategoryName1] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportSubcategoryName2] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportSubcategoryName3] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportOrder] [int] NOT NULL CONSTRAINT [DF_Charge_ReportOrder] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[DisplayTransactionalProductPriceOnInvoiceFlag] [bit] NOT NULL CONSTRAINT [DF_CHARGE_DisplayTransactionalProductPriceOnInvoiceFlag] DEFAULT ((1)),
[AllowLongerContractFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_AllowLongerContractFlag] DEFAULT ((0)),
[ProrateFirstMonthFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_ProrateFirstMonthFlag] DEFAULT ((0)),
[LeadDays] [int] NOT NULL CONSTRAINT [DF_Charge_LeadDays] DEFAULT ((60)),
[SystemAutoCreateEnablerFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_SystemAutoCreateEnablerFlag] DEFAULT ((1)),
[ValidateSiteMasterIDFlag] [bit] NOT NULL CONSTRAINT [DF_Charge_ValidateSiteMasterIDFlag] DEFAULT ((0)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Charge_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Charge_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Charge_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [products].[TRG_CHARGE_DELETE] on [products].[Charge] AFTER DELETE 
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_CHARGE_DELETE'))) = 1
BEGIN
  declare @LVC_ProductCode  varchar(100)
  declare @LN_PriceVersion  numeric(18,0)
  declare @LVC_ErrorMessage varchar(255)

  select @LVC_ProductCode = ProductCode,@LN_PriceVersion = PriceVersion
  from   DELETED

  if exists(select top 1 1 from Product P with (nolock)
            where P.Code         = @LVC_ProductCode
            and   P.PriceVersion = @LN_PriceVersion
            and   P.DisabledFlag = 0
            and   P.PendingApprovalFlag = 0
           )
  begin
    select @LVC_ErrorMessage = 'Charge is associated to an Active Product.' + @LVC_ProductCode + 
                               '. Hence cannot be deleted'
    RAISERROR (@LVC_ErrorMessage, 16, 1)
    ROLLBACK TRANSACTION
  end
END
GO
ALTER TABLE [products].[Charge] ADD CONSTRAINT [PK_ProductPricing] PRIMARY KEY CLUSTERED  ([ChargeIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CHARGE_PCMF] ON [products].[Charge] ([ProductCode], [ChargeTypeCode], [MeasureCode], [FrequencyCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Products_Charge_Productcode] ON [products].[Charge] ([ProductCode], [PriceVersion]) INCLUDE ([ChargeAmount], [ChargeTypeCode], [CommissionMaxPercent], [CreateDate], [CreatedBy], [CreditCardPercentageEnabledFlag], [CredtCardPricingPercentage], [CrossFireCallPricingEnabledFlag], [DeferredRevenueAccountCode], [DisabledFlag], [DiscountMaxPercent], [DisplayType], [DollarMaximum], [DollarMaximumEnabledFlag], [DollarMinimum], [DollarMinimumEnabledFlag], [EndDate], [ExplodeQuantityatOrderFlag], [FlatPriceFlag], [FrequencyCode], [MarkAsPrintedFlag], [MaxThresholdOverride], [MaxUnits], [MeasureCode], [MinThresholdOverride], [MinUnits], [ModifiedBy], [ModifyDate], [PriceByBedEnabledFlag], [QuantityEnabledFlag], [QuantityMultiplierFlag], [ReportingTypeCode], [RevenueAccountCode], [RevenueRecognitionCode], [RevenueTierCode], [SeparateInvoiceGroupNumber], [SiebelProductID], [SRSDisplayQuantityFlag], [StartDate], [TaxwareCode], [UnitBasis]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_Products_Charge_Measure] ON [products].[Charge] ([ProductCode], [PriceVersion], [MeasureCode], [FrequencyCode], [ChargeTypeCode]) INCLUDE ([ChargeAmount], [CommissionMaxPercent], [CreateDate], [CreatedBy], [CreditCardPercentageEnabledFlag], [CredtCardPricingPercentage], [CrossFireCallPricingEnabledFlag], [DeferredRevenueAccountCode], [DisabledFlag], [DiscountMaxPercent], [DisplayType], [DollarMaximum], [DollarMaximumEnabledFlag], [DollarMinimum], [DollarMinimumEnabledFlag], [EndDate], [ExplodeQuantityatOrderFlag], [FlatPriceFlag], [MarkAsPrintedFlag], [MaxThresholdOverride], [MaxUnits], [MinThresholdOverride], [MinUnits], [ModifiedBy], [ModifyDate], [PriceByBedEnabledFlag], [QuantityEnabledFlag], [QuantityMultiplierFlag], [ReportingTypeCode], [RevenueAccountCode], [RevenueRecognitionCode], [RevenueTierCode], [SeparateInvoiceGroupNumber], [SiebelProductID], [SRSDisplayQuantityFlag], [StartDate], [TaxwareCode], [UnitBasis]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Charge_RECORDSTAMP] ON [products].[Charge] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[Charge] WITH NOCHECK ADD CONSTRAINT [Charge_has_ChargeType] FOREIGN KEY ([ChargeTypeCode]) REFERENCES [products].[ChargeType] ([Code])
GO
ALTER TABLE [products].[Charge] WITH NOCHECK ADD CONSTRAINT [Charge_has_Frequency] FOREIGN KEY ([FrequencyCode]) REFERENCES [products].[Frequency] ([Code])
GO
ALTER TABLE [products].[Charge] WITH NOCHECK ADD CONSTRAINT [Charge_has_Measure] FOREIGN KEY ([MeasureCode]) REFERENCES [products].[Measure] ([Code])
GO
ALTER TABLE [products].[Charge] WITH NOCHECK ADD CONSTRAINT [Charge_has_Product] FOREIGN KEY ([ProductCode], [PriceVersion]) REFERENCES [products].[Product] ([Code], [PriceVersion])
GO
ALTER TABLE [products].[Charge] WITH NOCHECK ADD CONSTRAINT [Charge_has_ReportingTypeCode] FOREIGN KEY ([ReportingTypeCode]) REFERENCES [products].[ReportingType] ([Code])
GO
ALTER TABLE [products].[Charge] WITH NOCHECK ADD CONSTRAINT [Charge_has_RevenueRecognition] FOREIGN KEY ([RevenueRecognitionCode]) REFERENCES [products].[RevenueRecognition] ([Code])
GO
EXEC sp_addextendedproperty N'MS_Description', N'deferred revenue account with fk to proddata.dbo.glchart. required only for IFL, ACS ', 'SCHEMA', N'products', 'TABLE', N'Charge', 'COLUMN', N'DeferredRevenueAccountCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'revenue account with fk to proddata.dbo.glchart. required', 'SCHEMA', N'products', 'TABLE', N'Charge', 'COLUMN', N'RevenueAccountCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'used for F&A reporting and MIS reporting', 'SCHEMA', N'products', 'TABLE', N'Charge', 'COLUMN', N'RevenueTierCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'identifies the type of product with Taxware', 'SCHEMA', N'products', 'TABLE', N'Charge', 'COLUMN', N'TaxwareCode'
GO
