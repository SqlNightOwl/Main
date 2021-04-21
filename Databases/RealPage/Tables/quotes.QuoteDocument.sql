CREATE TABLE [quotes].[QuoteDocument]
(
[QDocIDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DocumentNote] [varchar] (8000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DocumentPath] [varchar] (500) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ActiveFlag] [int] NOT NULL CONSTRAINT [DF_QuoteDocument_ActiveFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QuoteDocument_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteDocument_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteDocument_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteDocument] ADD CONSTRAINT [PK_QuoteDocument] PRIMARY KEY CLUSTERED  ([QDocIDSeq] DESC, [QuoteIDSeq] DESC) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteDocument] WITH NOCHECK ADD CONSTRAINT [QUOTES_has_QuoteDocument] FOREIGN KEY ([QuoteIDSeq]) REFERENCES [quotes].[Quote] ([QuoteIDSeq])
GO
