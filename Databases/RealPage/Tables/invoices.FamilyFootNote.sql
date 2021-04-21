CREATE TABLE [invoices].[FamilyFootNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[FamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (8000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_FamilyFootNote_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_FamilyFootNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_FamilyFootNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[FamilyFootNote] ADD CONSTRAINT [PK_FamilyFootNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_FamilyFootNote_RECORDSTAMP] ON [invoices].[FamilyFootNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
