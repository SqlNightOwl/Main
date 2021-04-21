CREATE TABLE [invoices].[InvoicePayment]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PaymentTransactionAuthorizationCode] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PaymentTransactionNumber] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PaymentTransactionDate] [datetime] NULL,
[PaymentMethod] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceTotalAmount] [money] NOT NULL CONSTRAINT [DF_InvoicePayment_InvoiceTotalAmount] DEFAULT ((0.00)),
[TotalPaidAmount] [money] NOT NULL CONSTRAINT [DF_InvoicePayment_TotalPaidAmount] DEFAULT ((0.00)),
[PaymentGatewayResponseCode] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoicePayment_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoicePayment_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoicePayment_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoicePayment] ADD CONSTRAINT [PK_InvoicePayment] PRIMARY KEY CLUSTERED  ([IDSeq] DESC, [InvoiceIDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_InvoicePayment_KeyColumns] ON [invoices].[InvoicePayment] ([InvoiceIDSeq] DESC) INCLUDE ([CreatedByIDSeq], [CreatedDate], [ModifiedByIDSeq], [ModifiedDate]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoicePayment] WITH NOCHECK ADD CONSTRAINT [InvoicePayment_has_InvoiceIDSeq] FOREIGN KEY ([InvoiceIDSeq]) REFERENCES [invoices].[Invoice] ([InvoiceIDSeq])
GO
