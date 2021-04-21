CREATE TABLE [invoices].[PrintBatch]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PrintDate] [datetime] NOT NULL CONSTRAINT [DF_PrintBatch_BatchID] DEFAULT (getdate()),
[PrintedBy] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Status] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[TotalCount] [bigint] NULL,
[ProcessCount] [bigint] NULL,
[ErrorCount] [bigint] NULL,
[PrintedCount] [bigint] NULL,
[EndDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[PrintBatch] ADD CONSTRAINT [PK_PrintBatch_BatchID] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
