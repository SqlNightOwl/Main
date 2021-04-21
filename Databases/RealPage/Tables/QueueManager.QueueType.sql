CREATE TABLE [QueueManager].[QueueType]
(
[QTypeIDSeq] [int] NOT NULL,
[QTypeName] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[QTypeDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ActiveFlag] [int] NOT NULL CONSTRAINT [DF_QueueType_ActiveFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QueueType_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QueueType_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QueueType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[QueueType] ADD CONSTRAINT [PK_QueueType] PRIMARY KEY CLUSTERED  ([QTypeIDSeq]) ON [PRIMARY]
GO
