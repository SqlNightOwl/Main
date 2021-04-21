CREATE TABLE [docs].[DocumentHistory]
(
[IDSeq] [numeric] (30, 0) NOT NULL IDENTITY(1, 1),
[DocumentIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[IterationCount] [bigint] NOT NULL CONSTRAINT [DF_DocumentHistory_IterationCount] DEFAULT ((0)),
[StatusCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentClassIDSeq] [bigint] NOT NULL,
[ScopeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_DocumentHistory_ScopeCode] DEFAULT ('PMC'),
[Name] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ContractIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreditMemoIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentHistory_ActiveFlag] DEFAULT ((1)),
[DocumentPath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AttachmentFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentHistory_AttachmentFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentHistory_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DocumentHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[DocumentHistory] ADD CONSTRAINT [PK_DocumentHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_DocumentHistory_RECORDSTAMP] ON [docs].[DocumentHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[DocumentHistory] WITH NOCHECK ADD CONSTRAINT [Document_has_DocumentHistory] FOREIGN KEY ([DocumentIDSeq]) REFERENCES [docs].[Document] ([DocumentIDSeq])
GO
