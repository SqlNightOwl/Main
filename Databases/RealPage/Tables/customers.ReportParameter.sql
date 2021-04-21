CREATE TABLE [customers].[ReportParameter]
(
[IDSeq] [int] NOT NULL,
[ReportIDSeq] [int] NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SortSeq] [tinyint] NOT NULL,
[SRSParameter] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SRSValueType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SRSValueLength] [int] NOT NULL,
[ParameterXML] [varchar] (3000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RequiredFlag] [bit] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SPOnlyFlag] [bit] NOT NULL CONSTRAINT [DF_ReportParameter_SPOnlyFlag] DEFAULT ((0)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ReportParameter_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ReportParameter_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ReportParameter_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ReportParameter_RECORDSTAMP] ON [customers].[ReportParameter] ([RECORDSTAMP]) ON [PRIMARY]
GO
