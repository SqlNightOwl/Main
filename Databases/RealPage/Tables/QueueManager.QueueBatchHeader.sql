CREATE TABLE [QueueManager].[QueueBatchHeader]
(
[QBHIDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[QTypeIDSeq] [int] NOT NULL,
[QBHDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[TotalSubmittedCount] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchHeader_TotalSubmittedCount] DEFAULT ((0)),
[TotalWaitingCount] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchHeader_TotalWaitingCount] DEFAULT ((0)),
[TotalInProcessCount] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchHeader_TotalInProcessCount] DEFAULT ((0)),
[TotalCompletedCount] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchHeader_TotalCompletedCount] DEFAULT ((0)),
[TotalFailedCount] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchHeader_TotalFailedCount] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchHeader_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QueueBatchHeader_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QueueBatchHeader_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[QueueBatchHeader] ADD CONSTRAINT [PK_QueueBatchHeader] PRIMARY KEY CLUSTERED  ([QBHIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QueueBatchHeader_CreatedBYAttributes] ON [QueueManager].[QueueBatchHeader] ([CreatedByIDSeq] DESC, [ModifiedByIDSeq] DESC) INCLUDE ([CreatedDate], [ModifiedDate], [QBHDescription], [QBHIDSeq], [QTypeIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QueueBatchHeader_CreatedDtAttributes] ON [QueueManager].[QueueBatchHeader] ([CreatedDate] DESC, [ModifiedDate] DESC) INCLUDE ([CreatedByIDSeq], [ModifiedByIDSeq], [QBHDescription], [QBHIDSeq], [QTypeIDSeq]) ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[QueueBatchHeader] WITH NOCHECK ADD CONSTRAINT [QueueBatchHeader_has_QTypeIDSeq] FOREIGN KEY ([QTypeIDSeq]) REFERENCES [QueueManager].[QueueType] ([QTypeIDSeq])
GO
