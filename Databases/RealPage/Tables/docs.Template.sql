CREATE TABLE [docs].[Template]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Version] [bigint] NOT NULL CONSTRAINT [DF_Template_Version] DEFAULT ((1)),
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FilePath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ItemCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PrintOnOrderFlag] [bit] NULL CONSTRAINT [DF_Template_ShowOnOrder] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Template_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Template_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Template_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [docs].[Template] ADD CONSTRAINT [PK_Template] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Template_RECORDSTAMP] ON [docs].[Template] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[Template] WITH NOCHECK ADD CONSTRAINT [Template_has_Item] FOREIGN KEY ([ItemCode]) REFERENCES [docs].[Item] ([Code])
GO
