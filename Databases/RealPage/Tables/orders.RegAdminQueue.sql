CREATE TABLE [orders].[RegAdminQueue]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[AccountIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderItemIDSeq] [bigint] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_RegAdminQueue_ CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[PushedToRegAdminFlag] [bit] NOT NULL CONSTRAINT [DF_RegAdminQueueTable_PushedToRegAdmin] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_RegAdminQueue_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_RegAdminQueue_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [orders].[RegAdminQueue] ADD CONSTRAINT [PK_RegAdminQueue] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
