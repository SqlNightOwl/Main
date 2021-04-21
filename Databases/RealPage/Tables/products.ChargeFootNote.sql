CREATE TABLE [products].[ChargeFootNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[ChargeIDSeq] [bigint] NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceVersion] [numeric] (18, 0) NOT NULL,
[ChargeTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[MeasureCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FrequencyCode] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FootNote] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DisabledFlag] [bit] NOT NULL CONSTRAINT [DF_ChargeFootNote_DisabledFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ChargeFootNote_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ChargeFootNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ChargeFootNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [products].[ChargeFootNote] ADD CONSTRAINT [PK_ChargeFootNote] PRIMARY KEY CLUSTERED  ([IDSeq], [ChargeIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ChargeFootNote_RECORDSTAMP] ON [products].[ChargeFootNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[ChargeFootNote] WITH NOCHECK ADD CONSTRAINT [ChargeFootNote_has_Charge] FOREIGN KEY ([ChargeIDSeq]) REFERENCES [products].[Charge] ([ChargeIDSeq])
GO
