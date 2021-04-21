CREATE TABLE [orders].[TransactionStatusType]
(
[Code] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TransactionStatusType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_TransactionStatusType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TransactionStatusType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[TransactionStatusType] ADD CONSTRAINT [PK_TransactionStatusType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_TransactionStatusType_RECORDSTAMP] ON [orders].[TransactionStatusType] ([RECORDSTAMP]) ON [PRIMARY]
GO
