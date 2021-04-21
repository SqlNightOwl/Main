CREATE TABLE [documents].[FootNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_FootNote_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_FootNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_FootNote_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[FootNote] ADD CONSTRAINT [PK_FootNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
