CREATE TABLE [customers].[ReportAssociatedSPCalls]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[ReportIDSeq] [int] NOT NULL,
[SPName] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ReportAssociatedSPCalls_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ReportAssociatedSPCalls_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ReportAssociatedSPCalls_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[ReportAssociatedSPCalls] ADD CONSTRAINT [PK_ReportAssociatedSPCalls] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
