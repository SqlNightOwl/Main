use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[SecureMessage_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[SecureMessage_load]
GO
CREATE TABLE [ihb].[SecureMessage_load] (
	[AgentName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CaseId] [int] NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[MemberName] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OpenedOn] [datetime] NOT NULL ,
	[ClosedOn] [datetime] NULL ,
	[Subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Status] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO