CREATE TABLE [customers].[PriceCapProperties]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProperties_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapProperties_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapProperties_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapProperties] ADD CONSTRAINT [PK_PriceCapProperties] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCapProperties_RECORDSTAMP] ON [customers].[PriceCapProperties] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapProperties] WITH NOCHECK ADD CONSTRAINT [PriceCapProperties_has_PriceCap] FOREIGN KEY ([PriceCapIDSeq]) REFERENCES [customers].[PriceCap] ([IDSeq])
GO
