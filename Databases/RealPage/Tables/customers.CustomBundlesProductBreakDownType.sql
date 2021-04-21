CREATE TABLE [customers].[CustomBundlesProductBreakDownType]
(
[Code] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CustomBundlesProductBreakDownType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CustomBundlesProductBreakDownType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CustomBundlesProductBreakDownType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[CustomBundlesProductBreakDownType] ADD CONSTRAINT [PK_CustomBundlesProductBreakDownType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CustomBundlesProductBreakDownType_RECORDSTAMP] ON [customers].[CustomBundlesProductBreakDownType] ([RECORDSTAMP]) ON [PRIMARY]
GO
