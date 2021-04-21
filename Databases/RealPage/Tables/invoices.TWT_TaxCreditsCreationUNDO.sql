CREATE TABLE [invoices].[TWT_TaxCreditsCreationUNDO]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[InvoiceIDSeq] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceItemIDSeq] [bigint] NULL,
[OrderIDSeq] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderItemID] [bigint] NULL,
[OrderGroupID] [bigint] NULL,
[Exempt] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreditTaxAmt] [money] NULL,
[CreditMemoIDSeq] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProcessLog] [varchar] (250) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RunDate] [datetime] NULL CONSTRAINT [DF__TWT_TaxCr__RunDa__56DBCA78] DEFAULT (getdate())
) ON [PRIMARY]
GO
