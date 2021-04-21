CREATE TABLE [invoices].[TWT_InvoicesWithNoPDF]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[DocumentIDSeq] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DocumentPath] [varchar] (8000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceIDSeq] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CompanyIDSeq] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CompanyName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountIDSeq] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RunDateTime] [datetime] NOT NULL CONSTRAINT [DF_TWT_InvoicesWithNoPDF_RunDateTime] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[TWT_InvoicesWithNoPDF] ADD CONSTRAINT [PK_TWT_InvoicesWithNoPDF] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
