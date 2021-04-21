CREATE TABLE [quotes].[GroupProperties]
(
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[GroupIDSeq] [bigint] NOT NULL,
[PropertyIDSeq] [char] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CustomerIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceTypeCode] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_GroupProperties_PriceTypeCode] DEFAULT ('Normal'),
[ThresholdOverrideFlag] [int] NOT NULL CONSTRAINT [DF_GroupProperties_ThresholdOverrideFlag] DEFAULT ((0)),
[AnnualizedILFAmount] [money] NOT NULL CONSTRAINT [DF_GroupProperties_AnnualizedILFAmount] DEFAULT ((0)),
[AnnualizedAccessAmount] [money] NOT NULL CONSTRAINT [DF_GroupProperties_AnnualizedAccessAmount] DEFAULT ((0)),
[Units] [int] NOT NULL CONSTRAINT [DF_GroupProperties_Units] DEFAULT ((0)),
[Beds] [int] NOT NULL CONSTRAINT [DF_GroupProperties_Beds] DEFAULT ((0)),
[PPUPercentage] [int] NOT NULL CONSTRAINT [DF_GroupProperties_PPUPercentage] DEFAULT ((100)),
[TransferredFlag] [bit] NOT NULL CONSTRAINT [DF_GroupProperties_TransferredFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_GroupProperties_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_GroupProperties_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_GroupProperties_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[GroupProperties] ADD CONSTRAINT [PK_GroupProperties] PRIMARY KEY CLUSTERED  ([QuoteIDSeq], [GroupIDSeq], [PropertyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_GroupProperties_GroupIDSeq] ON [quotes].[GroupProperties] ([GroupIDSeq], [QuoteIDSeq]) INCLUDE ([AnnualizedAccessAmount], [AnnualizedILFAmount], [Beds], [CustomerIDSeq], [PPUPercentage], [PriceTypeCode], [PropertyIDSeq], [ThresholdOverrideFlag], [TransferredFlag], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_GroupProperties_RECORDSTAMP] ON [quotes].[GroupProperties] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[GroupProperties] WITH NOCHECK ADD CONSTRAINT [GroupProperties_has_Group] FOREIGN KEY ([QuoteIDSeq], [GroupIDSeq]) REFERENCES [quotes].[Group] ([QuoteIDSeq], [IDSeq])
GO
