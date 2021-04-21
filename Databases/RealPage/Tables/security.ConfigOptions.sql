CREATE TABLE [security].[ConfigOptions]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PageName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConfigOption] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConfigValue] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RowIdentifier] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ConfigOptions_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ConfigOptions_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ConfigOptions_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ConfigOptions_RECORDSTAMP] ON [security].[ConfigOptions] ([RECORDSTAMP]) ON [PRIMARY]
GO
