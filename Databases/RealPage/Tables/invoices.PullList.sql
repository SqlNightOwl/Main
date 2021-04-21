CREATE TABLE [invoices].[PullList]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Title] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL,
[ModifiedByIDSeq] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PullList_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[DisplayFalg] [bit] NOT NULL CONSTRAINT [DF_PullList_DisplayFalg] DEFAULT ((1)),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[PullList] ADD CONSTRAINT [PK_PullList] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PullList_RECORDSTAMP] ON [invoices].[PullList] ([RECORDSTAMP]) ON [PRIMARY]
GO
