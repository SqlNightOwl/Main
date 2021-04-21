CREATE TABLE [invoices].[BatchProcessDetail]
(
[IDSEQ] [bigint] NOT NULL IDENTITY(1, 1),
[EpicorBatchCode] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[BatchType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BatchDate] [datetime] NULL,
[InvoiceIDSeq] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreditMemoIDSeq] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SentToEpicorFailureMessage] [varchar] (2000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_BatchProcessDetail_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_BatchProcessDetail_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_BatchProcessDetail_SystemLogDate] DEFAULT (getdate()),
[EpicorCompanyName] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[BatchProcessDetail] ADD CONSTRAINT [PK_BatchProcessDetail] PRIMARY KEY CLUSTERED  ([IDSEQ], [EpicorBatchCode]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[BatchProcessDetail] WITH NOCHECK ADD CONSTRAINT [BatchProcessDetail_has_BatchProcess] FOREIGN KEY ([EpicorBatchCode], [EpicorCompanyName]) REFERENCES [invoices].[BatchProcess] ([EpicorBatchCode], [EpicorCompanyName])
GO
