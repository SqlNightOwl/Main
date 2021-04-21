CREATE TABLE [invoices].[BatchProcess]
(
[EpicorBatchCode] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[BatchType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_BatchProcess_BatchType] DEFAULT ('INVOICE'),
[Status] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_BatchProcess_Status] DEFAULT ('EPICOR PUSH PENDING'),
[InvoiceCount] [int] NOT NULL CONSTRAINT [DF_BatchProcess_InvoiceCount] DEFAULT ((0)),
[SuccessCount] [int] NOT NULL CONSTRAINT [DF_BatchProcess_SuccessCount] DEFAULT ((0)),
[FailureCount] [int] NOT NULL CONSTRAINT [DF_BatchProcess_FailureCount] DEFAULT ((0)),
[ProcessCount] [int] NOT NULL CONSTRAINT [DF_BatchProcess_ProcessCount] DEFAULT ((0)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_BatchProcess_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NULL,
[CreatedBy] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_BatchProcess_CreatedBy] DEFAULT ('MIS System'),
[StartDate] [datetime] NULL,
[EndDate] [datetime] NULL,
[ErrorMessage] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CashReceiptEpicorBatchCode] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_BatchProcess_SystemLogDate] DEFAULT (getdate()),
[EpicorCompanyName] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [invoices].[BatchProcess] ADD CONSTRAINT [PK_BatchProcess] PRIMARY KEY CLUSTERED  ([EpicorBatchCode], [EpicorCompanyName]) ON [PRIMARY]
GO
