CREATE TABLE [security].[User]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[NTUser] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FirstName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Title] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Email] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastLoginDate] [datetime] NULL,
[CreatedDate] [datetime] NOT NULL,
[CreatedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[ActiveFlag] [bit] NULL,
[Department] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DeactivationDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_User_RECORDSTAMP] ON [security].[User] ([RECORDSTAMP]) ON [PRIMARY]
GO
