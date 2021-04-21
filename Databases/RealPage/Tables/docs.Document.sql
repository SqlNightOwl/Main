CREATE TABLE [docs].[Document]
(
[DocumentIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[IterationCount] [bigint] NOT NULL CONSTRAINT [DF_Document_IterationCount] DEFAULT ((0)),
[StatusCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentClassIDSeq] [bigint] NOT NULL,
[ScopeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Document_ScopeCode] DEFAULT ('PMC'),
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
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_Document_ActiveFlag] DEFAULT ((1)),
[DocumentPath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AttachmentFlag] [bit] NOT NULL CONSTRAINT [DF_Document_AttachmentFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Document_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Document_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Document_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[Document] ADD CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED  ([DocumentIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Document_RECORDSTAMP] ON [docs].[Document] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[Document] WITH NOCHECK ADD CONSTRAINT [Document_has_Contract] FOREIGN KEY ([ContractIDSeq]) REFERENCES [docs].[Contract] ([IDSeq])
GO
ALTER TABLE [docs].[Document] WITH NOCHECK ADD CONSTRAINT [Document_has_DocumentClass1] FOREIGN KEY ([DocumentClassIDSeq]) REFERENCES [docs].[DocumentClass] ([IDSeq])
GO
ALTER TABLE [docs].[Document] WITH NOCHECK ADD CONSTRAINT [Document_has_Scope] FOREIGN KEY ([ScopeCode]) REFERENCES [docs].[Scope] ([code])
GO
ALTER TABLE [docs].[Document] WITH NOCHECK ADD CONSTRAINT [Document_has_Status] FOREIGN KEY ([StatusCode]) REFERENCES [docs].[Status] ([Code])
GO
