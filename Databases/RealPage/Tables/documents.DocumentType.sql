CREATE TABLE [documents].[DocumentType]
(
[Code] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DocumentType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentType_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[DocumentType] ADD CONSTRAINT [PK_DocumentType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
