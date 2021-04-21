CREATE TABLE [invoices].[TWT_ProdInvoices]
(
[BillingCycleDate] [datetime] NULL,
[Createddate] [datetime] NOT NULL,
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AccountIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PropertyName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToAccountName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BusinessUnit] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BillToDeliveryOptionCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[InvoiceTotal] [money] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test2] ON [invoices].[TWT_ProdInvoices] ([AccountIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test7] ON [invoices].[TWT_ProdInvoices] ([BillToAccountName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test3] ON [invoices].[TWT_ProdInvoices] ([CompanyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test5] ON [invoices].[TWT_ProdInvoices] ([CompanyName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test1] ON [invoices].[TWT_ProdInvoices] ([InvoiceIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test4] ON [invoices].[TWT_ProdInvoices] ([PropertyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ITWT_Test6] ON [invoices].[TWT_ProdInvoices] ([PropertyName]) ON [PRIMARY]
GO
