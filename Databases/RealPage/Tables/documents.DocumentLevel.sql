CREATE TABLE [documents].[DocumentLevel]
(
[Code] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentLevel_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DocumentLevel_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentLevel_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[DocumentLevel] ADD CONSTRAINT [PK_DocumentLevel] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
