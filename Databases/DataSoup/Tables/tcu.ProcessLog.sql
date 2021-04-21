use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessLog]
GO
CREATE TABLE [tcu].[ProcessLog] (
	[ProcessLogId] [int] IDENTITY (1, 1) NOT NULL ,
	[RunId] [int] NOT NULL ,
	[ProcessId] [smallint] NOT NULL ,
	[ScheduleId] [tinyint] NOT NULL ,
	[StartedOn] [datetime] NOT NULL ,
	[FinishedOn] [datetime] NOT NULL ,
	[Result] [tinyint] NOT NULL ,
	[Command] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Message] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_ProcessLog] PRIMARY KEY  CLUSTERED 
	(
		[ProcessLogId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RunProcessSchedule] ON [tcu].[ProcessLog]([RunId], [ProcessId], [ScheduleId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_FinishedOn] ON [tcu].[ProcessLog]([FinishedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_ProcessSchedule] ON [tcu].[ProcessLog]([ProcessId], [ScheduleId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Process_Result] ON [tcu].[ProcessLog]([ProcessId], [Result]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_StartedOn] ON [tcu].[ProcessLog]([StartedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Result] ON [tcu].[ProcessLog]([Result]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Process_Schedule_Finished] ON [tcu].[ProcessLog]([Result]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Process_Schedule_Result] ON [tcu].[ProcessLog]([ProcessId], [ScheduleId], [Result]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Result_Process] ON [tcu].[ProcessLog]([Result]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Process] ON [tcu].[ProcessLog]([ProcessId]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessLog].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessLog].[CreatedOn]'
GO
setuser
GO