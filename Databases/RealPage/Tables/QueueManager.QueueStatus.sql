CREATE TABLE [QueueManager].[QueueStatus]
(
[Status] [int] NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QueueStatus_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QueueStatus_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QueueStatus_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[QueueStatus] ADD CONSTRAINT [PK_QueueStatus] PRIMARY KEY CLUSTERED  ([Status]) ON [PRIMARY]
GO
