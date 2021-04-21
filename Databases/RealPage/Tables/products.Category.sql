CREATE TABLE [products].[Category]
(
[Code] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SortSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Category_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Category_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Category_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[Category] ADD CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Category_RECORDSTAMP] ON [products].[Category] ([RECORDSTAMP]) ON [PRIMARY]
GO
