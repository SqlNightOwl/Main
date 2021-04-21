CREATE TABLE [security].[Rights]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[LockableFlag] [bit] NOT NULL CONSTRAINT [DF_rights_LockableFlag] DEFAULT ((0)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Rights_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Rights_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Rights_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Rights_RECORDSTAMP] ON [security].[Rights] ([RECORDSTAMP]) ON [PRIMARY]
GO
