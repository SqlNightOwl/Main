CREATE TABLE [customers].[Report]
(
[IDSeq] [int] NOT NULL,
[CategoryIDSeq] [int] NOT NULL,
[Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (250) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SRSPath] [varchar] (250) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ExportType] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedDate] [datetime] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[Excel2007Only] [bit] NOT NULL CONSTRAINT [DF_Report_Excel2007Only] DEFAULT ((0)),
[RightIDSeq] [bigint] NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Report_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Report_SystemLogDate] DEFAULT (getdate()),
[LabelComments] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_Report_Name] ON [customers].[Report] ([Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Report_RECORDSTAMP] ON [customers].[Report] ([RECORDSTAMP]) ON [PRIMARY]
GO
