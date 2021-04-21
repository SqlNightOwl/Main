CREATE TABLE [documents].[Agreement]
(
[IDSeq] [numeric] (18, 0) NOT NULL IDENTITY(1, 1),
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OwnerIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[StatusCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Version] [numeric] (18, 0) NULL,
[Iteration] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
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
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Agreement_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Agreement_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[Agreement] ADD CONSTRAINT [PK_DocumentMetaData] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
ALTER TABLE [documents].[Agreement] WITH NOCHECK ADD CONSTRAINT [Agreement_has_StatusCode] FOREIGN KEY ([StatusCode]) REFERENCES [documents].[AgreementStatus] ([Code])
GO
ALTER TABLE [documents].[Agreement] WITH NOCHECK ADD CONSTRAINT [Agreement_has_TypeCode] FOREIGN KEY ([TypeCode]) REFERENCES [documents].[AgreementType] ([Code])
GO
