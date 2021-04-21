CREATE TABLE [security].[UserAudit]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[AuditCode] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NTUser] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserIDSeq] [bigint] NULL,
[CreatedDate] [datetime] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_UserAudit_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_UserAudit_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [security].[UserAudit] ADD CONSTRAINT [PK_UserAudit] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_UserAudit_RECORDSTAMP] ON [security].[UserAudit] ([RECORDSTAMP]) ON [PRIMARY]
GO
