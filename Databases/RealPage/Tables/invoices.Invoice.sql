CREATE TABLE [invoices].[Invoice]
(
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PropertyName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BarcodeID] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ILFChargeAmount] [money] NOT NULL CONSTRAINT [DF_Invoice_ILFChargeAmount] DEFAULT ((0)),
[AccessChargeAmount] [money] NOT NULL CONSTRAINT [DF_Invoice_AccessChargeAmount] DEFAULT ((0)),
[TransactionChargeAmount] [money] NOT NULL CONSTRAINT [DF_Invoice_TransactionChargeAmount] DEFAULT ((0)),
[TaxAmount] [money] NOT NULL CONSTRAINT [DF_Invoice_TaxAmount] DEFAULT ((0)),
[CreditAmount] [money] NOT NULL CONSTRAINT [DF_Invoice_CreditAmount] DEFAULT ((0)),
[ShippingAndHandlingAmount] [money] NOT NULL CONSTRAINT [DF_Invoice_ShippingAndHandlingAmount] DEFAULT ((0)),
[StatusCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[InvoiceTerms] [int] NOT NULL CONSTRAINT [DF_Invoice_InvoiceTerms] DEFAULT ((30)),
[InvoiceDate] [datetime] NULL,
[InvoiceDueDate] [datetime] NULL,
[InvoiceSentToAddressIDSeq] [int] NULL,
[OriginalPrintDate] [datetime] NULL,
[PrintFlag] [int] NOT NULL CONSTRAINT [DF_Invoice_PrintFlag] DEFAULT ((1)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL,
[ModifiedDate] [datetime] NULL,
[ApplyDate] [datetime] NULL,
[RePrintDate] [datetime] NULL,
[PrintCount] [bigint] NOT NULL CONSTRAINT [DF__Invoice__RePrint__5B196B42] DEFAULT ((0)),
[EpicorBatchCode] [varchar] (16) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SentToEpicorFlag] [bit] NOT NULL CONSTRAINT [DF__Invoice__SentToE__06C2E356] DEFAULT ((0)),
[SentToEpicorStatus] [varchar] (25) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[EpicorCustomerCode] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToAccountName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToAccountName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Units] [int] NULL,
[Beds] [int] NULL,
[PPUPercentage] [int] NULL,
[BillToAttentionName] [nchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToPMCFlag] [bit] NULL,
[BillToAddressLine1] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToAddressLine2] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToCity] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToCounty] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToState] [varchar] (2) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToZip] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToCountry] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToPhoneVoice] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToPhoneVoiceExt] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToPhoneFax] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToPMCFlag] [bit] NULL,
[ShipToAddressLine1] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToAddressLine2] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToCity] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToCounty] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToState] [varchar] (2) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToZip] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToCountry] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SentToEpicorMessage] [varchar] (400) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToCountryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ShipToCountryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PrintBatchID] [bigint] NULL,
[DocLinkPrintBatchID] [bigint] NULL,
[SentToDocLinkFlag] [bit] NOT NULL CONSTRAINT [DF_Invoice_SentToDocLinkFlag] DEFAULT ((0)),
[BillToAddressTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SeparateInvoiceGroupNumber] [bigint] NOT NULL CONSTRAINT [DF_Invoice_SeparateInvoiceGroupNumber] DEFAULT ((0)),
[MarkAsPrintedFlag] [bit] NOT NULL CONSTRAINT [DF_Invoice_MarkAsPrintedFlag] DEFAULT ((0)),
[MainInvoicePageCount] [int] NOT NULL CONSTRAINT [DF_Invoice_MainInvoicePageCount] DEFAULT ((0)),
[SubInvoicePageCount] [int] NOT NULL CONSTRAINT [DF_Invoice_SubInvoicePageCount] DEFAULT ((0)),
[TotalPageCount] AS ([MainInvoicePageCount]+[SubInvoicePageCount]),
[RECORDSTAMP] [timestamp] NOT NULL,
[EpicorPostingCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Invoice_EpicorPostingCode] DEFAULT ('RPI'),
[TaxwareCompanyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Invoice_TaxwareCompanyCode] DEFAULT ('01'),
[SendInvoiceToClientFlag] [bit] NOT NULL CONSTRAINT [DF_INVOICE_SendInvoiceToClientFlag] DEFAULT ((1)),
[BillToEmailAddress] [varchar] (2000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToDeliveryOptionCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_INVOICE_BillToDeliveryOptionCode] DEFAULT ('SMAIL'),
[BillingCycleDate] [datetime] NULL,
[XMLProcessingStatus] [int] NOT NULL CONSTRAINT [DF_INVOICE_ProcessingStatus] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Invoice_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Invoice_SystemLogDate] DEFAULT (getdate()),
[PrePaidFlag] [int] NOT NULL CONSTRAINT [DF_Invoice_PrePaidFlag] DEFAULT ((0)),
[ValidFlag] [int] NOT NULL CONSTRAINT [DF_Invoice_ValidFlag] DEFAULT ((1)),
[ExternalQuoteIIFlag] [int] NOT NULL CONSTRAINT [DF_Invoice_ExternalQuoteIIFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[Invoice] ADD CONSTRAINT [PK_Invoice] PRIMARY KEY CLUSTERED  ([InvoiceIDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoice_AccountIDSeq] ON [invoices].[Invoice] ([AccountIDSeq], [CompanyIDSeq], [PropertyIDSeq], [BillToAddressTypeCode], [BillToDeliveryOptionCode]) INCLUDE ([AccessChargeAmount], [BillingCycleDate], [CreditAmount], [ILFChargeAmount], [InvoiceIDSeq], [PrePaidFlag], [PrintFlag], [SendInvoiceToClientFlag], [SentToDocLinkFlag], [SentToEpicorFlag], [ShippingAndHandlingAmount], [TaxAmount], [TransactionChargeAmount], [XMLProcessingStatus]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Invoice_BillingCycleDate_InvoiceDate] ON [invoices].[Invoice] ([BillingCycleDate] DESC, [InvoiceDate] DESC, [PrintFlag]) INCLUDE ([AccessChargeAmount], [AccountIDSeq], [BillToAccountName], [BillToAddressLine1], [BillToAddressLine2], [BillToAddressTypeCode], [BillToAttentionName], [BillToCity], [BillToCountry], [BillToCountryCode], [BillToCounty], [BillToDeliveryOptionCode], [BillToState], [BillToZip], [CompanyIDSeq], [CompanyName], [CreditAmount], [EpicorBatchCode], [EpicorPostingCode], [ILFChargeAmount], [InvoiceIDSeq], [MarkAsPrintedFlag], [PrePaidFlag], [PropertyIDSeq], [PropertyName], [SendInvoiceToClientFlag], [SentToDocLinkFlag], [SentToEpicorFlag], [SeparateInvoiceGroupNumber], [ShippingAndHandlingAmount], [ShipToAccountName], [ShipToAddressLine1], [ShipToAddressLine2], [ShipToCity], [ShipToCountry], [ShipToCountryCode], [ShipToCounty], [ShipToState], [ShipToZip], [TaxAmount], [TaxwareCompanyCode], [TransactionChargeAmount], [XMLProcessingStatus]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoice_BillTo] ON [invoices].[Invoice] ([BillToCity], [BillToState], [BillToZip], [BillToAddressLine1], [BillToAddressTypeCode], [BillToDeliveryOptionCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoice_CompanyName] ON [invoices].[Invoice] ([CompanyName], [CompanyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoice_PropertyName] ON [invoices].[Invoice] ([PropertyName], [PropertyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Invoice_RECORDSTAMP] ON [invoices].[Invoice] ([RECORDSTAMP]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoice_ShipToAddress] ON [invoices].[Invoice] ([ShipToAddressLine1]) INCLUDE ([AccessChargeAmount], [AccountIDSeq], [AccountTypeCode], [ApplyDate], [BarcodeID], [Beds], [BillToAccountName], [BillToAddressLine1], [BillToAddressLine2], [BillToAddressTypeCode], [BillToAttentionName], [BillToCity], [BillToCountry], [BillToCountryCode], [BillToCounty], [BillToPhoneFax], [BillToPhoneVoice], [BillToPhoneVoiceExt], [BillToPMCFlag], [BillToState], [BillToZip], [CompanyIDSeq], [CompanyName], [CreatedBy], [CreatedDate], [CreditAmount], [EpicorBatchCode], [EpicorCustomerCode], [ILFChargeAmount], [InvoiceDate], [InvoiceDueDate], [InvoiceIDSeq], [InvoiceSentToAddressIDSeq], [InvoiceTerms], [MarkAsPrintedFlag], [ModifiedBy], [ModifiedDate], [OriginalPrintDate], [PPUPercentage], [PrintBatchID], [PrintCount], [PrintFlag], [PropertyIDSeq], [PropertyName], [RePrintDate], [SentToEpicorFlag], [SentToEpicorMessage], [SentToEpicorStatus], [SeparateInvoiceGroupNumber], [ShippingAndHandlingAmount], [ShipToAccountName], [ShipToAddressLine2], [ShipToCity], [ShipToCountry], [ShipToCountryCode], [ShipToCounty], [ShipToPMCFlag], [ShipToState], [ShipToZip], [StatusCode], [TaxAmount], [TransactionChargeAmount], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoice_ShipTo] ON [invoices].[Invoice] ([ShipToCity], [ShipToState], [ShipToZip], [ShipToAddressLine1]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[Invoice] WITH NOCHECK ADD CONSTRAINT [Invoice_has_DocLinkPrintBatchID] FOREIGN KEY ([PrintBatchID]) REFERENCES [invoices].[PrintBatch] ([IDSeq])
GO
ALTER TABLE [invoices].[Invoice] WITH NOCHECK ADD CONSTRAINT [Invoice_has_PrintBatchID] FOREIGN KEY ([PrintBatchID]) REFERENCES [invoices].[PrintBatch] ([IDSeq])
GO
ALTER TABLE [invoices].[Invoice] WITH NOCHECK ADD CONSTRAINT [Invoice_has_InvoiceStatusType] FOREIGN KEY ([StatusCode]) REFERENCES [invoices].[InvoiceStatusType] ([Code])
GO
