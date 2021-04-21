use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[SecureMessage]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[SecureMessage]
GO
CREATE TABLE [ihb].[SecureMessage] (
	[CaseId] [int] NOT NULL ,
	[AgentName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[MemberName] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OpenedOn] [datetime] NOT NULL ,
	[ClosedOn] [datetime] NULL ,
	[Subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Status] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MessageCount] [int] NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_SecureMessage] PRIMARY KEY  CLUSTERED 
	(
		[CaseId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ClosedOn] ON [ihb].[SecureMessage]([ClosedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CreatedOn] ON [ihb].[SecureMessage]([CreatedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OpenedOn] ON [ihb].[SecureMessage]([OpenedOn]) ON [PRIMARY]
GO