CREATE TABLE [products].[REVENUE_TIER_TRANSLATION]
(
[RevenueTierID] [int] NOT NULL IDENTITY(1, 1),
[revenue_tier_code] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[product_name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[service_code] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[revenue_tier_rule] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[core_code] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillingAnalysisName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[IsSite] [varchar] (1) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[GroupLevel] [int] NULL,
[ReportLabelForQTY] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MarketSorting] [int] NULL,
[SubGroupName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DisplaySiteInfo] [varchar] (1) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShowQty] [varchar] (1) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF__REVENUE_T__Creat__592635D8] DEFAULT (getdate()),
[CreatedBy] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[LastUpdatedDate] [datetime] NOT NULL CONSTRAINT [DF__REVENUE_T__LastU__5A1A5A11] DEFAULT (getdate()),
[LastUpdatedBy] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DeactivatedDate] [datetime] NULL,
[IsExcludedReporting] [bit] NOT NULL CONSTRAINT [DF__REVENUE_T__IsExc__5B0E7E4A] DEFAULT ((0)),
[IsActive] [bit] NULL CONSTRAINT [DF__REVENUE_T__IsAct__5C02A283] DEFAULT ((1)),
[SiebelProductID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PlatformCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CategoryCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProductTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RevenueAccountCode] [varchar] (32) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DeferredAccountCode] [varchar] (32) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportTier1] [varchar] (510) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportTier2] [varchar] (510) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportTier3] [varchar] (510) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportTier4] [varchar] (510) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReportingEndDate] [datetime] NULL,
[MoveNewProductMappingFlag] [bit] NOT NULL CONSTRAINT [DF__REVENUE_T__MoveN__5CF6C6BC] DEFAULT ((1)),
[ReviewedFlag] [bit] NOT NULL CONSTRAINT [DF__REVENUE_T__Revie__5DEAEAF5] DEFAULT ((0)),
[IncludePPCFlag] [bit] NOT NULL CONSTRAINT [DF__REVENUE_T__Inclu__5EDF0F2E] DEFAULT ((0)),
[ReportOrder] [smallint] NULL,
[ManualRevenueRecFlag] [bit] NOT NULL CONSTRAINT [DF__REVENUE_T__Manua__5FD33367] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [products].[REVENUE_TIER_TRANSLATION] ADD CONSTRAINT [PK_revenue_tier_translation_table] PRIMARY KEY CLUSTERED  ([revenue_tier_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_CategoryCode] ON [products].[REVENUE_TIER_TRANSLATION] ([CategoryCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_ChargeTypeCode] ON [products].[REVENUE_TIER_TRANSLATION] ([ChargeTypeCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_FamilyCode] ON [products].[REVENUE_TIER_TRANSLATION] ([FamilyCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_FrequencyCode] ON [products].[REVENUE_TIER_TRANSLATION] ([FrequencyCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_MeasureCode] ON [products].[REVENUE_TIER_TRANSLATION] ([MeasureCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_PlatformCode] ON [products].[REVENUE_TIER_TRANSLATION] ([PlatformCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RevTierTrans_ProductTypeCode] ON [products].[REVENUE_TIER_TRANSLATION] ([ProductTypeCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_REVENUE_TIER_TRANSLATION_RECORDSTAMP] ON [products].[REVENUE_TIER_TRANSLATION] ([RECORDSTAMP]) ON [PRIMARY]
GO
