CREATE TABLE [QueueManager].[QueueBatchDetail]
(
[QBDIDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[QBHIDSeq] [bigint] NOT NULL,
[QTypeIDSeq] [int] NOT NULL,
[QBDDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProcessStatus] [int] NOT NULL CONSTRAINT [DF_QueueBatchDetail_Process] DEFAULT ((0)),
[CommandXML] [xml] NULL,
[ProcessStartDate] [datetime] NULL,
[ProcessEndDate] [datetime] NULL,
[ProcessErrorMessage] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QueueBatchDetail_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QueueBatchDetail_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QueueBatchDetail_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[QueueBatchDetail] ADD CONSTRAINT [PK_QueueBatchDetail] PRIMARY KEY CLUSTERED  ([QBDIDSeq], [QBHIDSeq], [QTypeIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QueueBatchDetail_CreatedBYAttributes] ON [QueueManager].[QueueBatchDetail] ([CreatedByIDSeq] DESC, [ModifiedByIDSeq] DESC) INCLUDE ([CreatedDate], [ModifiedDate], [ProcessStatus], [QBDDescription], [QBDIDSeq], [QBHIDSeq], [QTypeIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QueueBatchDetail_CreatedDtAttributes] ON [QueueManager].[QueueBatchDetail] ([CreatedDate] DESC, [ModifiedDate] DESC) INCLUDE ([CreatedByIDSeq], [ModifiedByIDSeq], [ProcessStatus], [QBDDescription], [QBDIDSeq], [QBHIDSeq], [QTypeIDSeq]) ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[QueueBatchDetail] WITH NOCHECK ADD CONSTRAINT [QueueBatchDetail_has_Status] FOREIGN KEY ([ProcessStatus]) REFERENCES [QueueManager].[QueueStatus] ([Status])
GO
ALTER TABLE [QueueManager].[QueueBatchDetail] WITH NOCHECK ADD CONSTRAINT [QueueBatchDetail_has_QTypeIDSeq] FOREIGN KEY ([QBHIDSeq]) REFERENCES [QueueManager].[QueueBatchHeader] ([QBHIDSeq])
GO
