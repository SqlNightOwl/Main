CREATE TABLE [security].[RoleRights]
(
[RoleIDSeq] [bigint] NOT NULL,
[RightIDSeq] [bigint] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_RoleRights_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_RoleRights_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_RoleRights_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_RoleRights_RECORDSTAMP] ON [security].[RoleRights] ([RECORDSTAMP]) ON [PRIMARY]
GO
