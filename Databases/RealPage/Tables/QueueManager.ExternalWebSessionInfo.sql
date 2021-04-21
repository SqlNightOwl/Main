CREATE TABLE [QueueManager].[ExternalWebSessionInfo]
(
[EWSIDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[EWSGUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ExternalWebSessionInfo_EWSGUID] DEFAULT (newsequentialid()),
[EWSessionXML] [xml] NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ExternalWebSessionInfo_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ExternalWebSessionInfo_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ExternalWebSessionInfo_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [QueueManager].[ExternalWebSessionInfo] ADD CONSTRAINT [PK_ExternalWebSessionInfo] PRIMARY KEY CLUSTERED  ([EWSIDSeq], [EWSGUID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ExternalWebSessionInfo_CreatedBYAttributes] ON [QueueManager].[ExternalWebSessionInfo] ([CreatedByIDSeq] DESC, [ModifiedByIDSeq] DESC) INCLUDE ([CreatedDate], [EWSessionXML], [EWSGUID], [EWSIDSeq], [ModifiedDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ExternalWebSessionInfo_CreatedDtAttributes] ON [QueueManager].[ExternalWebSessionInfo] ([CreatedDate] DESC, [ModifiedDate] DESC) INCLUDE ([CreatedByIDSeq], [EWSessionXML], [EWSGUID], [EWSIDSeq], [ModifiedByIDSeq]) ON [PRIMARY]
GO
