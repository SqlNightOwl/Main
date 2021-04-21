CREATE TABLE [docs].[Contract]
(
[IDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OwnerIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DocumentIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TemplateIDSeq] [bigint] NULL,
[TemplateVersion] [bigint] NULL,
[Author] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PMCSignBy] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PMCSignByTitle] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OwnerSignBy] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OwnerSignByTitle] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RealPageSignBy] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RealPageSignByTitle] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ScannedDocuments_CreatedDate] DEFAULT (getdate()),
[SubmittedDate] [datetime] NULL,
[ReceivedDate] [datetime] NULL,
[ExecutedDate] [datetime] NULL,
[BeginDate] [datetime] NULL,
[ExpireDate] [datetime] NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedDate] [datetime] NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Contract_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Contract_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[Contract] ADD CONSTRAINT [PK_DocumentMetaData] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Contract_RECORDSTAMP] ON [docs].[Contract] ([RECORDSTAMP]) ON [PRIMARY]
GO
