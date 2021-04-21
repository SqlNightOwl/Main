CREATE TABLE [products].[Product]
(
[Code] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceVersion] [numeric] (18, 0) NOT NULL,
[PlatformCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CategoryCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ItemCode] [char] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SortSeq] [int] NOT NULL CONSTRAINT [DF_Product_SortSeq] DEFAULT ((0)),
[Name] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DisplayName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OptionFlag] [bit] NOT NULL CONSTRAINT [DF_Product_OptionFlag] DEFAULT ((0)),
[SOCFlag] [int] NOT NULL CONSTRAINT [DF_Product_SOCFlag] DEFAULT ((1)),
[DisabledFlag] [bit] NOT NULL CONSTRAINT [DF_Product_DisabledFlag_1] DEFAULT ((0)),
[StartDate] [datetime] NOT NULL CONSTRAINT [DF_Product_StartDate] DEFAULT (((1)/(1))/(2001)),
[EndDate] [datetime] NULL CONSTRAINT [DF_Product_EndDate] DEFAULT (((1)/(1))/(2029)),
[CreatedBy] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Product_CreateDate] DEFAULT (getdate()),
[ModifyDate] [datetime] NULL CONSTRAINT [DF_Product_ModifyDate] DEFAULT (getdate()),
[PriceCapEnabledFlag] [bit] NOT NULL CONSTRAINT [DF__Product__PriceCa__4B973090] DEFAULT ((1)),
[PendingApprovalFlag] [bit] NOT NULL CONSTRAINT [DF_Product_PendingApprovalFlag] DEFAULT ((1)),
[ExcludeForBookingsFlag] [bit] NOT NULL CONSTRAINT [DF_Products_ProductExcludeForBookingsFlag] DEFAULT ((0)),
[stockbundleflag] [bit] NOT NULL CONSTRAINT [DF_Product_stockbundleflag] DEFAULT ((0)),
[LegacyProductCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RegAdminProductFlag] [bit] NOT NULL CONSTRAINT [DF_Product_RegAdminProductFlag] DEFAULT ((0)),
[ReportPrimaryProductFlag] [bit] NOT NULL CONSTRAINT [DF_Product_ReportPrimaryProductFlag] DEFAULT ((0)),
[MPFPublicationFlag] [bit] NOT NULL CONSTRAINT [DF_Product_MPFPublicationFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[StockBundleIdentifierCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AutoFulfillFlag] [bit] NOT NULL CONSTRAINT [DF_AutoFulfillFlag_AutoFulfillFlag] DEFAULT ((0)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Product_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Product_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Product_SystemLogDate] DEFAULT (getdate()),
[PrePaidFlag] [int] NOT NULL CONSTRAINT [DF_Charge_PrePaidFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [products].[TRG_PRODUCT_DELETE] on [products].[Product] AFTER DELETE 
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_PRODUCT_DELETE'))) = 1
BEGIN
  declare @LVC_ProductCode  varchar(100)
  declare @LN_PriceVersion  numeric(18,0)
  declare @LVC_ErrorMessage varchar(255)

  select @LVC_ProductCode = Code,@LN_PriceVersion = PriceVersion
  from   DELETED

  if exists(select top 1 1 from Product P with (nolock)
            where P.Code         = @LVC_ProductCode
            and   P.PriceVersion = @LN_PriceVersion
            and   P.DisabledFlag = 0
            and   P.PendingApprovalFlag = 0
           )
  begin
    select @LVC_ErrorMessage = 'Product :' + @LVC_ProductCode + ' Version : ' + convert(varchar(100),@LN_PriceVersion)+
                               ' is an Active Product. Hence cannot be deleted'
    RAISERROR (@LVC_ErrorMessage, 16, 1)
    ROLLBACK TRANSACTION
  end
END
GO
ALTER TABLE [products].[Product] ADD CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED  ([Code], [PriceVersion]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_Product_Code] ON [products].[Product] ([Code], [PriceVersion], [PlatformCode], [FamilyCode], [CategoryCode], [ProductTypeCode], [ItemCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Products_Product_DisplayName] ON [products].[Product] ([DisplayName]) INCLUDE ([CategoryCode], [Code], [CreateDate], [CreatedBy], [Description], [DisabledFlag], [EndDate], [ExcludeForBookingsFlag], [FamilyCode], [ItemCode], [LegacyProductCode], [ModifiedBy], [ModifyDate], [Name], [OptionFlag], [PendingApprovalFlag], [PlatformCode], [PriceCapEnabledFlag], [PriceVersion], [ProductTypeCode], [RegAdminProductFlag], [SOCFlag], [SortSeq], [StartDate], [stockbundleflag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Products_Product_Family] ON [products].[Product] ([FamilyCode], [CategoryCode], [ProductTypeCode]) INCLUDE ([Code], [CreateDate], [CreatedBy], [Description], [DisabledFlag], [DisplayName], [EndDate], [ExcludeForBookingsFlag], [ItemCode], [LegacyProductCode], [ModifiedBy], [ModifyDate], [Name], [OptionFlag], [PendingApprovalFlag], [PlatformCode], [PriceCapEnabledFlag], [PriceVersion], [RegAdminProductFlag], [SOCFlag], [SortSeq], [StartDate], [stockbundleflag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PRODUCT_FCC] ON [products].[Product] ([FamilyCode], [Code], [CategoryCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Products_Product_Name] ON [products].[Product] ([Name]) INCLUDE ([CategoryCode], [Code], [CreateDate], [CreatedBy], [Description], [DisabledFlag], [DisplayName], [EndDate], [ExcludeForBookingsFlag], [FamilyCode], [ItemCode], [LegacyProductCode], [ModifiedBy], [ModifyDate], [OptionFlag], [PendingApprovalFlag], [PlatformCode], [PriceCapEnabledFlag], [PriceVersion], [ProductTypeCode], [RegAdminProductFlag], [SOCFlag], [SortSeq], [StartDate], [stockbundleflag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Product_RECORDSTAMP] ON [products].[Product] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[Product] WITH NOCHECK ADD CONSTRAINT [Product_has_Category] FOREIGN KEY ([CategoryCode]) REFERENCES [products].[Category] ([Code])
GO
ALTER TABLE [products].[Product] WITH NOCHECK ADD CONSTRAINT [Product_has_Family] FOREIGN KEY ([FamilyCode]) REFERENCES [products].[Family] ([Code])
GO
ALTER TABLE [products].[Product] WITH NOCHECK ADD CONSTRAINT [Product_has_Platform] FOREIGN KEY ([PlatformCode]) REFERENCES [products].[Platform] ([Code])
GO
ALTER TABLE [products].[Product] WITH NOCHECK ADD CONSTRAINT [Product_has_ProductType] FOREIGN KEY ([ProductTypeCode]) REFERENCES [products].[ProductType] ([Code])
GO
ALTER TABLE [products].[Product] WITH NOCHECK ADD CONSTRAINT [Product_has_StockBundleIdentifier] FOREIGN KEY ([StockBundleIdentifierCode]) REFERENCES [products].[StockBundleIdentifier] ([Code])
GO
