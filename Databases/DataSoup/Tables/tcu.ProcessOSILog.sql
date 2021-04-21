use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessOSILog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessOSILog]
GO
CREATE TABLE [tcu].[ProcessOSILog] (
	[ProcessOSILogId] [int] IDENTITY (1, 1) NOT NULL ,
	[RunId] [int] NOT NULL ,
	[ProcessId] [smallint] NOT NULL ,
	[EffectiveOn] [datetime] NOT NULL ,
	[ApplName] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DailyOffset] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[QueNbr] [int] NOT NULL ,
	[QueDesc] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FileName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CompletedOn] [datetime] NOT NULL ,
	[FileDate] [datetime] NOT NULL ,
	[FileSize] [int] NOT NULL ,
	[FileCount] [int] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_ProcessOSILog] PRIMARY KEY  CLUSTERED 
	(
		[ProcessOSILogId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ProcessRun] ON [tcu].[ProcessOSILog]([RunId], [ProcessId]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Process] ON [tcu].[ProcessOSILog]([ProcessId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EffectiveOn] ON [tcu].[ProcessOSILog]([EffectiveOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplName] ON [tcu].[ProcessOSILog]([ApplName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DailyOffset] ON [tcu].[ProcessOSILog]([DailyOffset]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QueNbr] ON [tcu].[ProcessOSILog]([QueNbr]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessOSILog].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessOSILog].[CreatedOn]'
GO
setuser
GO