CREATE TABLE [invoices].[PullListAccounts]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PullListIDSeq] [bigint] NOT NULL,
[AccountIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PullListAccounts_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PullListAccounts_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PullListAccounts_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[PullListAccounts] ADD CONSTRAINT [PK_PullListAccounts] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PullListAccounts_AccountID] ON [invoices].[PullListAccounts] ([PullListIDSeq], [AccountIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PullListAccounts_RECORDSTAMP] ON [invoices].[PullListAccounts] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[PullListAccounts] WITH NOCHECK ADD CONSTRAINT [PullListAccounts_has_PullList] FOREIGN KEY ([PullListIDSeq]) REFERENCES [invoices].[PullList] ([IDSeq])
GO
