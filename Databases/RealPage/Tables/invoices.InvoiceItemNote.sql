CREATE TABLE [invoices].[InvoiceItemNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[InvoiceItemIDSeq] [bigint] NOT NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderItemIDSeq] [bigint] NOT NULL,
[OrderItemTransactionIDSeq] [bigint] NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MandatoryFlag] [bit] NOT NULL CONSTRAINT [DF_InvoiceItemNote_FootNote] DEFAULT ((0)),
[PrintOnInvoiceFlag] [bit] NOT NULL CONSTRAINT [DF_InvoiceItemNote_PrintOnInvoiceFlag] DEFAULT ((1)),
[SortSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceItemNote_SortSeq] DEFAULT ((99999)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceItemNote_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceItemNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceItemNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceItemNote] ADD CONSTRAINT [PK_InvoiceItemNote] PRIMARY KEY CLUSTERED  ([IDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Invoices_Invoiceitemnote_InvoiceIDseq_InvoiceItemIDSeq] ON [invoices].[InvoiceItemNote] ([InvoiceIDSeq] DESC, [InvoiceItemIDSeq] DESC, [OrderIDSeq] DESC, [OrderItemIDSeq] DESC, [OrderItemTransactionIDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_InvoiceItemNote_RECORDSTAMP] ON [invoices].[InvoiceItemNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceItemNote] WITH NOCHECK ADD CONSTRAINT [InvoiceItemNote_has_Invoice] FOREIGN KEY ([InvoiceIDSeq]) REFERENCES [invoices].[Invoice] ([InvoiceIDSeq])
GO
ALTER TABLE [invoices].[InvoiceItemNote] WITH NOCHECK ADD CONSTRAINT [InvoiceItemNote_has_InvoiceItem] FOREIGN KEY ([InvoiceItemIDSeq]) REFERENCES [invoices].[InvoiceItem] ([IDSeq])
GO
