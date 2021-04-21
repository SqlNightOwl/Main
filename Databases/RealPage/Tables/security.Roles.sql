CREATE TABLE [security].[Roles]
(
[IDSeq] [bigint] NOT NULL,
[Code] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_Roles_ActiveFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Roles_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Roles_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
