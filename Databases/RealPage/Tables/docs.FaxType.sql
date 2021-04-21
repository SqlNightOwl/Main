CREATE TABLE [docs].[FaxType]
(
[Code] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_FaxType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_FaxType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_FaxType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[FaxType] ADD CONSTRAINT [PK_FaxType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_FaxType_RECORDSTAMP] ON [docs].[FaxType] ([RECORDSTAMP]) ON [PRIMARY]
GO
