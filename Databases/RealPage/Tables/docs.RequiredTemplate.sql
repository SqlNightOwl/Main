CREATE TABLE [docs].[RequiredTemplate]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[TemplateIDSeq] [bigint] NOT NULL,
[FamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_RequiredTemplate_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_RequiredTemplate_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_RequiredTemplate_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[RequiredTemplate] ADD CONSTRAINT [PK_RequiredTemplate] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RequiredTemplate] ON [docs].[RequiredTemplate] ([FamilyCode], [ProductCode], [TemplateIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RequiredTemplate_RECORDSTAMP] ON [docs].[RequiredTemplate] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[RequiredTemplate] WITH NOCHECK ADD CONSTRAINT [RequiredTemplate_has_Template] FOREIGN KEY ([TemplateIDSeq]) REFERENCES [docs].[Template] ([IDSeq])
GO
