CREATE TABLE [invoices].[CreditMemo]
(
[CreditMemoIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ILFCreditAmount] [money] NOT NULL CONSTRAINT [DF_CreditMemo_TotalCreditAmount] DEFAULT ((0)),
[AccessCreditAmount] [money] NOT NULL CONSTRAINT [DF_CreditMemo_AccessCreditAmount] DEFAULT ((0)),
[TransactionCreditAmount] [money] NOT NULL CONSTRAINT [DF_CreditMemo_TransactionCreditAmount] DEFAULT ((0)),
[ShippingAndHandlingCreditAmount] [money] NOT NULL CONSTRAINT [DF_CreditMemo_ShippingAndHandlingCreditAmount] DEFAULT ((0)),
[TotalNetCreditAmount] [money] NOT NULL CONSTRAINT [DF_CreditMemo_TotalNetCreditAmount] DEFAULT ((0)),
[TaxAmount] [money] NOT NULL CONSTRAINT [DF_CreditMemo_TotalTaxAmount] DEFAULT ((0)),
[CreditTypeCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreditStatusCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreditReasonCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RequestedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ApprovedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CreditMemo_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[RequestedDate] [datetime] NOT NULL CONSTRAINT [DF_CreditMemo_RequestedDate] DEFAULT (getdate()),
[ApprovedDate] [datetime] NULL,
[Comments] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyDate] [datetime] NULL,
[EpicorBatchCode] [varchar] (16) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SentToEpicorFlag] [bit] NOT NULL CONSTRAINT [DF__CreditMem__SentT__30A40E89] DEFAULT ((0)),
[SentToEpicorStatus] [varchar] (25) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SentToDocLinkFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_SentToDocLinkFlag] DEFAULT ((0)),
[RevisedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RevisedDate] [datetime] NULL,
[DoNotPrintCreditReasonFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_DoNotPrintCreditReasonFlag] DEFAULT ((1)),
[DoNotPrintCreditCommentsFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_DoNotPrintCreditCommentsFlag] DEFAULT ((1)),
[IncludeAccountsManagerSignatureFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_IncludeAccountsManagerSignatureFlag] DEFAULT ((1)),
[IncludeSoftwareRevenueDirectorSignatureFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_IncludeSoftwareRevenueDirectorFlag] DEFAULT ((1)),
[IncludeVicePresidentFinanceSignatureFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_IncludeVicePresidentFinanceSignatureFlag] DEFAULT ((1)),
[IncludeProductManagerSignatureFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_IncludeProductManagerSignatureFlag] DEFAULT ((0)),
[IncludeVicePresidentSalesSignatureFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_IncludeVicePresidentSalesSignatureFlag] DEFAULT ((0)),
[IncludeChiefFinancialOfficerSignatureFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_IncludeChiefFinancialOfficerSignatureFlag] DEFAULT ((0)),
[SentToEpicorMessage] [varchar] (400) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PrintFlag] [int] NOT NULL CONSTRAINT [DF_CreditMemo_PrintFlag] DEFAULT ((0)),
[CreditMemoDate] [datetime] NULL,
[CreditMemoReversalFlag] [int] NOT NULL CONSTRAINT [DF_CreditMemo_CreditMemoReversalFlag] DEFAULT ((0)),
[ApplyToCreditMemoIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SeparateInvoiceGroupNumber] [bigint] NOT NULL CONSTRAINT [DF_CreditMemo_SeparateInvoiceGroupNumber] DEFAULT ((0)),
[MarkAsPrintedFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemo_MarkAsPrintedFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[EpicorPostingCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_CreditMemo_EpicorPostingCode] DEFAULT ('RPI'),
[TaxwareCompanyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_CreditMemo_TaxwareCompanyCode] DEFAULT ('01'),
[CancelledBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CancelledDate] [datetime] NULL,
[ReversedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ReversedDate] [datetime] NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CreditMemo_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CreditMemo_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[CreditMemo] ADD CONSTRAINT [PK_CreditMemo] PRIMARY KEY CLUSTERED  ([CreditMemoIDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_CreditMemo_CreditStatusCode] ON [invoices].[CreditMemo] ([CreditStatusCode], [RequestedBy]) INCLUDE ([AccessCreditAmount], [ApplyDate], [ApplyToCreditMemoIDSeq], [ApprovedBy], [ApprovedDate], [Comments], [CreatedBy], [CreatedDate], [CreditMemoDate], [CreditMemoIDSeq], [CreditMemoReversalFlag], [CreditReasonCode], [CreditTypeCode], [DoNotPrintCreditCommentsFlag], [DoNotPrintCreditReasonFlag], [EpicorBatchCode], [ILFCreditAmount], [IncludeAccountsManagerSignatureFlag], [IncludeChiefFinancialOfficerSignatureFlag], [IncludeProductManagerSignatureFlag], [IncludeSoftwareRevenueDirectorSignatureFlag], [IncludeVicePresidentFinanceSignatureFlag], [IncludeVicePresidentSalesSignatureFlag], [InvoiceIDSeq], [MarkAsPrintedFlag], [ModifiedBy], [ModifiedDate], [PrintFlag], [RequestedDate], [RevisedBy], [RevisedDate], [SentToEpicorFlag], [SentToEpicorMessage], [SentToEpicorStatus], [SeparateInvoiceGroupNumber], [ShippingAndHandlingCreditAmount], [TaxAmount], [TotalNetCreditAmount], [TransactionCreditAmount]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_CreditMemo_InvoiceIDSeq] ON [invoices].[CreditMemo] ([InvoiceIDSeq]) INCLUDE ([AccessCreditAmount], [ApplyDate], [ApplyToCreditMemoIDSeq], [ApprovedBy], [ApprovedDate], [Comments], [CreatedBy], [CreatedDate], [CreditMemoDate], [CreditMemoIDSeq], [CreditMemoReversalFlag], [CreditReasonCode], [CreditStatusCode], [CreditTypeCode], [DoNotPrintCreditCommentsFlag], [DoNotPrintCreditReasonFlag], [EpicorBatchCode], [ILFCreditAmount], [IncludeAccountsManagerSignatureFlag], [IncludeChiefFinancialOfficerSignatureFlag], [IncludeProductManagerSignatureFlag], [IncludeSoftwareRevenueDirectorSignatureFlag], [IncludeVicePresidentFinanceSignatureFlag], [IncludeVicePresidentSalesSignatureFlag], [MarkAsPrintedFlag], [ModifiedBy], [ModifiedDate], [PrintFlag], [RequestedBy], [RequestedDate], [RevisedBy], [RevisedDate], [SentToEpicorFlag], [SentToEpicorMessage], [SentToEpicorStatus], [SeparateInvoiceGroupNumber], [ShippingAndHandlingCreditAmount], [TaxAmount], [TotalNetCreditAmount], [TransactionCreditAmount]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CreditMemo_RECORDSTAMP] ON [invoices].[CreditMemo] ([RECORDSTAMP]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_CreditMemo_RequestedBy] ON [invoices].[CreditMemo] ([RequestedBy]) INCLUDE ([AccessCreditAmount], [ApplyDate], [ApplyToCreditMemoIDSeq], [ApprovedBy], [ApprovedDate], [Comments], [CreatedBy], [CreatedDate], [CreditMemoDate], [CreditMemoIDSeq], [CreditMemoReversalFlag], [CreditReasonCode], [CreditStatusCode], [CreditTypeCode], [DoNotPrintCreditCommentsFlag], [DoNotPrintCreditReasonFlag], [EpicorBatchCode], [ILFCreditAmount], [IncludeAccountsManagerSignatureFlag], [IncludeChiefFinancialOfficerSignatureFlag], [IncludeProductManagerSignatureFlag], [IncludeSoftwareRevenueDirectorSignatureFlag], [IncludeVicePresidentFinanceSignatureFlag], [IncludeVicePresidentSalesSignatureFlag], [InvoiceIDSeq], [MarkAsPrintedFlag], [ModifiedBy], [ModifiedDate], [PrintFlag], [RequestedDate], [RevisedBy], [RevisedDate], [SentToEpicorFlag], [SentToEpicorMessage], [SentToEpicorStatus], [SeparateInvoiceGroupNumber], [ShippingAndHandlingCreditAmount], [TaxAmount], [TotalNetCreditAmount], [TransactionCreditAmount]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[CreditMemo] WITH NOCHECK ADD CONSTRAINT [CreditMemo_has_ApplyToCreditMemoIDSeq] FOREIGN KEY ([ApplyToCreditMemoIDSeq]) REFERENCES [invoices].[CreditMemo] ([CreditMemoIDSeq])
GO
ALTER TABLE [invoices].[CreditMemo] WITH NOCHECK ADD CONSTRAINT [CreditMemo_has_CreditStatusType] FOREIGN KEY ([CreditStatusCode]) REFERENCES [invoices].[CreditStatusType] ([Code])
GO
ALTER TABLE [invoices].[CreditMemo] WITH NOCHECK ADD CONSTRAINT [CreditMemo_has_CreditType] FOREIGN KEY ([CreditTypeCode]) REFERENCES [invoices].[CreditType] ([Code])
GO
ALTER TABLE [invoices].[CreditMemo] WITH NOCHECK ADD CONSTRAINT [CreditMemo_has_Invoice] FOREIGN KEY ([InvoiceIDSeq]) REFERENCES [invoices].[Invoice] ([InvoiceIDSeq])
GO
