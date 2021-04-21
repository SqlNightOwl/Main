CREATE TABLE [products].[ReportingType]
(
[Code] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SortSeq] [bigint] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ReportingType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ReportingType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ReportingType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[ReportingType] ADD CONSTRAINT [PK_ReportingType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_ReportingType_Name] ON [products].[ReportingType] ([Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ReportingType_RECORDSTAMP] ON [products].[ReportingType] ([RECORDSTAMP]) ON [PRIMARY]
GO
