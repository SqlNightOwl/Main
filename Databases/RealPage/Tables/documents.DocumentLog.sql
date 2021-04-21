CREATE TABLE [documents].[DocumentLog]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentLevelCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderItemIDSeq] [bigint] NULL,
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceItemIDSeq] [bigint] NULL,
[CreditMemoIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreditMemoItemIDSeq] [bigint] NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AgreementAddendum] [varchar] (3000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AgreementExecutedFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentLog_AgreementExecutedFlag] DEFAULT ((0)),
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentLog_ActiveFlag] DEFAULT ((1)),
[DocumentPath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AttachmentFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentLog_AttachmentFlag] DEFAULT ((0)),
[AgreementSignedDate] [datetime] NULL,
[AgreementSentDate] [datetime] NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentLog_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[LogDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentLog_LogDate] DEFAULT (getdate()),
[QuoteItemIDSeq] [bigint] NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DocumentLog_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentLog_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[DocumentLog] ADD CONSTRAINT [PK_DocumentLog] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
ALTER TABLE [documents].[DocumentLog] WITH NOCHECK ADD CONSTRAINT [DocumentLog_has_Document] FOREIGN KEY ([DocumentIDSeq]) REFERENCES [documents].[Document] ([DocumentIDSeq])
GO
