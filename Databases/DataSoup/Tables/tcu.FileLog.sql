use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[FileLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[FileLog]
GO
CREATE TABLE [tcu].[FileLog] (
	[RunId] [int] NOT NULL ,
	[ProcessId] [int] NOT NULL ,
	[FileId] [int] NOT NULL ,
	[Path] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SubFolder] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FileName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FileDate] [datetime] NOT NULL ,
	[FileSize] [int] NOT NULL ,
	[FileCount] [int] NOT NULL ,
	[IsNewest] [bit] NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_FileLog] PRIMARY KEY  CLUSTERED 
	(
		[RunId],
		[ProcessId],
		[FileId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileDate] ON [tcu].[FileLog]([FileDate]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RunId] ON [tcu].[FileLog]([RunId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileId] ON [tcu].[FileLog]([FileId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ProcessId] ON [tcu].[FileLog]([ProcessId]) ON [PRIMARY]
GO