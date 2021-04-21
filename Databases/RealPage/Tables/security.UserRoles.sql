CREATE TABLE [security].[UserRoles]
(
[UserIDSeq] [bigint] NOT NULL,
[RoleIDSeq] [bigint] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_UserRoles_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_UserRoles_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_UserRoles_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_UserRoles_RECORDSTAMP] ON [security].[UserRoles] ([RECORDSTAMP]) ON [PRIMARY]
GO
