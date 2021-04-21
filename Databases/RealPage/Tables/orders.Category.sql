CREATE TABLE [orders].[Category]
(
[Code] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CategoryName] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Category_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Category_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Category_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[Category] ADD CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IXNUQ_Category_CategoryName] ON [orders].[Category] ([CategoryName]) INCLUDE ([Code]) ON [PRIMARY]
GO
