CREATE TABLE [customers].[ReportCategory]
(
[IDSeq] [int] NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (250) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SortSeq] [int] NOT NULL,
[RightIDSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ReportCategory_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ReportCategory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ReportCategory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ReportCategory_RECORDSTAMP] ON [customers].[ReportCategory] ([RECORDSTAMP]) ON [PRIMARY]
GO
