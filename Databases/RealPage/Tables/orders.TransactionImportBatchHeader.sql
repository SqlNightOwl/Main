CREATE TABLE [orders].[TransactionImportBatchHeader]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[BatchName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[EstimatedImportCount] [bigint] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_EstimatedImportCount] DEFAULT ((0)),
[ActualImportCount] [bigint] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_ActualImportCount] DEFAULT ((0)),
[ErrorCount] [bigint] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_ErrorCount] DEFAULT ((0)),
[EstimatedNetChargeAmount] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_EstimatedNetChargeAmount] DEFAULT ((0.00)),
[TotalNetChargeAmount] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_TotalNetChargeAmount] DEFAULT ((0.00)),
[ImportSource] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_ImportSource] DEFAULT ('EXCEL'),
[ImportedFileName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BatchPostingStatusFlag] [int] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_StatusFlag] DEFAULT ((0)),
[ErrorMessage] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RollBackByIDSeq] [bigint] NULL,
[RollBackReasonCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RollBackDate] [datetime] NULL,
[CreatedByIDSeq] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TransactionImportBatchHeader_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [orders].[TransactionImportBatchHeader] ADD CONSTRAINT [PK_TransactionImport] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_TransactionImportBatchHeader_CreatedAttributes] ON [orders].[TransactionImportBatchHeader] ([CreatedByIDSeq], [ModifiedByIDSeq]) INCLUDE ([ActualImportCount], [BatchName], [BatchPostingStatusFlag], [CreatedDate], [ErrorCount], [EstimatedImportCount], [EstimatedNetChargeAmount], [ImportSource], [ModifiedDate], [TotalNetChargeAmount]) ON [PRIMARY]
GO
