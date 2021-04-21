CREATE TABLE [products].[ProductTranslation]
(
[Siebel77ProductID] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Siebel77ProductName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[NewProductName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[NewProductCode] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProductTranslationIDSeq] [int] NOT NULL IDENTITY(1, 1),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF__ProductTr__Creat__4C8B54C9] DEFAULT (getdate()),
[LastModifiedDate] [datetime] NOT NULL CONSTRAINT [DF__ProductTr__LastM__4D7F7902] DEFAULT (getdate()),
[NewProductPriceVersion] [numeric] (18, 0) NOT NULL CONSTRAINT [DF__ProductTr__NewPr__2E90DD8E] DEFAULT ((100)),
[RECORDSTAMP] [timestamp] NOT NULL,
[PrimaryOMSProductFlag] [bit] NULL CONSTRAINT [DF__ProductTr__Prima__77D5A581] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ProductTranslation_RECORDSTAMP] ON [products].[ProductTranslation] ([RECORDSTAMP]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IXN_ProductTranslation_Siebel77ProductID_NewProductCode] ON [products].[ProductTranslation] ([Siebel77ProductID], [NewProductCode]) ON [PRIMARY]
GO
