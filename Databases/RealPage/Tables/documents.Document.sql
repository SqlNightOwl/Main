CREATE TABLE [documents].[Document]
(
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
[AgreementAddendum] [varchar] (6000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AgreementExecutedFlag] [bit] NOT NULL CONSTRAINT [DF_Document_AgreementExecutedFlag] DEFAULT ((0)),
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_Document_ActiveFlag] DEFAULT ((1)),
[DocumentPath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AttachmentFlag] [bit] NOT NULL CONSTRAINT [DF_Document_AttachmentFlag] DEFAULT ((0)),
[AgreementSignedDate] [datetime] NULL,
[AgreementSentDate] [datetime] NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Document_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[PrintOnInvoiceFlag] [bit] NOT NULL CONSTRAINT [DF_Document_PrintOnInvoiceFlag] DEFAULT ((0)),
[QuoteItemIDSeq] [bigint] NULL,
[AgreementIDSeq] [numeric] (18, 0) NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Document_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Document_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [documents].[Document] ADD CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED  ([DocumentIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Documents_Document_AccountID] ON [documents].[Document] ([AccountIDSeq], [CompanyIDSeq], [PropertyIDSeq], [DocumentTypeCode], [DocumentLevelCode]) INCLUDE ([ActiveFlag], [AgreementAddendum], [AgreementExecutedFlag], [AgreementSentDate], [AgreementSignedDate], [AttachmentFlag], [CreatedBy], [CreatedDate], [CreditMemoIDSeq], [CreditMemoItemIDSeq], [Description], [DocumentIDSeq], [DocumentPath], [FamilyCode], [InvoiceIDSeq], [InvoiceItemIDSeq], [ModifiedBy], [ModifiedDate], [Name], [OrderIDSeq], [OrderItemIDSeq], [PrintOnInvoiceFlag], [QuoteIDSeq], [QuoteItemIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Documents_Document_QuoteOrderID] ON [documents].[Document] ([AccountIDSeq], [CompanyIDSeq], [QuoteIDSeq], [OrderIDSeq], [InvoiceIDSeq], [CreditMemoIDSeq]) INCLUDE ([ActiveFlag], [AgreementAddendum], [AgreementExecutedFlag], [AgreementSentDate], [AgreementSignedDate], [AttachmentFlag], [CreatedBy], [CreatedDate], [CreditMemoItemIDSeq], [Description], [DocumentIDSeq], [DocumentLevelCode], [DocumentPath], [DocumentTypeCode], [FamilyCode], [InvoiceItemIDSeq], [ModifiedBy], [ModifiedDate], [Name], [OrderItemIDSeq], [PrintOnInvoiceFlag], [PropertyIDSeq], [QuoteItemIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Document_RECORDSTAMP] ON [documents].[Document] ([RECORDSTAMP]) ON [PRIMARY]
GO
