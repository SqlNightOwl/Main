CREATE TABLE [quotes].[QuoteItemNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MandatoryFlag] [bit] NOT NULL CONSTRAINT [DF_QuoteItemNote_FootNote] DEFAULT ((0)),
[PrintOnOrderFormFlag] [bit] NOT NULL CONSTRAINT [DF_QuoteItemNote_PrintFlag] DEFAULT ((1)),
[SortSeq] [bigint] NOT NULL CONSTRAINT [DF_QuoteItemNote_SortSeq] DEFAULT ((99999)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteItemNote_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QuoteItemNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteItemNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteItemNote] ADD CONSTRAINT [PK_QuoteItemNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_Quoteitemnote_QuoteIDseq] ON [quotes].[QuoteItemNote] ([QuoteIDSeq]) INCLUDE ([CreatedDate], [Description], [IDSeq], [MandatoryFlag], [PrintOnOrderFormFlag], [SortSeq], [Title]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QuoteItemNote_RECORDSTAMP] ON [quotes].[QuoteItemNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteItemNote] WITH NOCHECK ADD CONSTRAINT [QuoteItemNote_has_QuoteIDSeq] FOREIGN KEY ([QuoteIDSeq]) REFERENCES [quotes].[Quote] ([QuoteIDSeq])
GO
