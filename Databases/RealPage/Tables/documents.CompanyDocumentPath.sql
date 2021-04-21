CREATE TABLE [documents].[CompanyDocumentPath]
(
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDDocumentPath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CompanyDocumentPath_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CompanyDocumentPath_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CompanyDocumentPath_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [documents].[CompanyDocumentPath] ADD CONSTRAINT [PK_DocumentPath] PRIMARY KEY CLUSTERED  ([CompanyIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CompanyDocumentPath_RECORDSTAMP] ON [documents].[CompanyDocumentPath] ([RECORDSTAMP]) ON [PRIMARY]
GO
