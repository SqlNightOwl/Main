CREATE TABLE [products].[TWT_D8_ProductUpdate]
(
[CurrentProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CurrentPlatFormCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[NewPlatFormCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[NewProductCode] [varchar] (31) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceVersion] [numeric] (18, 0) NOT NULL,
[PlatformCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CategoryCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ItemCode] [char] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL
) ON [PRIMARY]
GO
