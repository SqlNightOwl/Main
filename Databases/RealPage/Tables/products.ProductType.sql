CREATE TABLE [products].[ProductType]
(
[Code] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SortSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[ReportPrimaryProductFlag] [int] NOT NULL CONSTRAINT [DF_Producttype_ReportPrimaryProductFlag] DEFAULT ((0)),
[MarketCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ProductType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ProductType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ProductType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[ProductType] ADD CONSTRAINT [PK_ProductType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ProductType_RECORDSTAMP] ON [products].[ProductType] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[ProductType] WITH NOCHECK ADD CONSTRAINT [ProductType_has_Market] FOREIGN KEY ([MarketCode]) REFERENCES [products].[Market] ([Code])
GO
