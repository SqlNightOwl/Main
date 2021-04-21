CREATE TABLE [docs].[DocumentClass]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[StructureCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SourceCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CategoryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ItemCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SharePointFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentClass_SharepointFlag] DEFAULT ((1)),
[CustomerPortalFlag] [bit] NOT NULL CONSTRAINT [DF_DocumentClass_CustomerPortalFlag] DEFAULT ((1)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentClass_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DocumentClass_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DocumentClass_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[DocumentClass] ADD CONSTRAINT [PK_DocumentClass] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_DocumentClass_RECORDSTAMP] ON [docs].[DocumentClass] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[DocumentClass] WITH NOCHECK ADD CONSTRAINT [Document_has_CategoryCode] FOREIGN KEY ([CategoryCode]) REFERENCES [docs].[Category] ([Code])
GO
ALTER TABLE [docs].[DocumentClass] WITH NOCHECK ADD CONSTRAINT [Document_has_ItemCode] FOREIGN KEY ([ItemCode]) REFERENCES [docs].[Item] ([Code])
GO
ALTER TABLE [docs].[DocumentClass] WITH NOCHECK ADD CONSTRAINT [Document_has_SourceCode] FOREIGN KEY ([SourceCode]) REFERENCES [docs].[Source] ([Code])
GO
ALTER TABLE [docs].[DocumentClass] WITH NOCHECK ADD CONSTRAINT [Document_has_DocumentClass] FOREIGN KEY ([StructureCode]) REFERENCES [docs].[Structure] ([Code])
GO
ALTER TABLE [docs].[DocumentClass] WITH NOCHECK ADD CONSTRAINT [Document_has_TypeCode] FOREIGN KEY ([TypeCode]) REFERENCES [docs].[Type] ([Code])
GO
