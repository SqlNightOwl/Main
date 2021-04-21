CREATE TABLE [dbo].[ProcedureRename]
(
[ProcedureId] [int] NOT NULL IDENTITY(1, 1),
[OriginalName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SchemaName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OMSName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BaseName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[New_Name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RuleApplied] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ProcedureRename] ADD CONSTRAINT [PK_ProcedureRename] PRIMARY KEY CLUSTERED  ([ProcedureId]) ON [PRIMARY]
GO
