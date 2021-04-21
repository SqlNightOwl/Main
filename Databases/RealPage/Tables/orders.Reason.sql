CREATE TABLE [orders].[Reason]
(
[Code] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ReasonName] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Reason_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Reason_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Reason_SystemLogDate] DEFAULT (getdate()),
[ReportDisplayBucketName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL
) ON [PRIMARY]
GO
ALTER TABLE [orders].[Reason] ADD CONSTRAINT [PK_Reason] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IXNUQ_Reason_ReasonName] ON [orders].[Reason] ([ReasonName]) INCLUDE ([Code]) ON [PRIMARY]
GO
