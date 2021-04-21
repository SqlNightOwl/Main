CREATE TABLE [products].[ScreeningProductMapping]
(
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreditUsedFlag] [bit] NOT NULL CONSTRAINT [DF_ScreeningProductMapping_CreditUsedFlag] DEFAULT ((0)),
[CriminalUsedFlag] [bit] NOT NULL CONSTRAINT [DF_ScreeningProductMapping_CriminalUsedFlag] DEFAULT ((0)),
[CountryCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Priority] [tinyint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ScreeningProductMapping_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ScreeningProductMapping_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ScreeningProductMapping_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ScreeningProductMapping_RECORDSTAMP] ON [products].[ScreeningProductMapping] ([RECORDSTAMP]) ON [PRIMARY]
GO
