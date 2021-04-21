CREATE TABLE [customers].[PriceCap]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentIDSeq] [bigint] NULL,
[PriceCapName] [varchar] (500) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceCapBasisCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_PriceCap_PriceCapBasisCode] DEFAULT ('LIST'),
[PriceCapPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_PriceCap_PriceCapPercent] DEFAULT ((0.00)),
[PriceCapTerm] [int] NOT NULL CONSTRAINT [DF_PriceCap_PriceCapTerm] DEFAULT ((0)),
[PriceCapStartDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCap_StartDate] DEFAULT (getdate()),
[PriceCapEndDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCap_EndDate] DEFAULT (getdate()),
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF__PriceCap__Active__70148828] DEFAULT ((1)),
[CreatedByID] [bigint] NULL,
[CreatedDate] [datetime] NULL,
[ModifiedByID] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[SystemGeneratedPriceCapFlag] [bit] NOT NULL CONSTRAINT [DF_PriceCap_SystemGeneratedPriceCapFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCap_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCap_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCap] ADD CONSTRAINT [PK_PriceCap] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCap_RECORDSTAMP] ON [customers].[PriceCap] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCap] WITH NOCHECK ADD CONSTRAINT [PriceCap_has_Company] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
