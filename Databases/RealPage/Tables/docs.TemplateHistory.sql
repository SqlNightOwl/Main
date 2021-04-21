CREATE TABLE [docs].[TemplateHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[TemplateIDSeq] [bigint] NOT NULL,
[Version] [bigint] NOT NULL CONSTRAINT [DF_TemplateHistory_Version] DEFAULT ((1)),
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FilePath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ItemCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TemplateHistory_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_TemplateHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TemplateHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[TemplateHistory] ADD CONSTRAINT [PK_TemplateHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_TemplateHistory_RECORDSTAMP] ON [docs].[TemplateHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[TemplateHistory] WITH NOCHECK ADD CONSTRAINT [Document_has_TemplateHistory] FOREIGN KEY ([TemplateIDSeq]) REFERENCES [docs].[Template] ([IDSeq])
GO
