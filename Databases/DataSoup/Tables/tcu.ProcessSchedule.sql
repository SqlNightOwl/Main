use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSchedule]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessSchedule]
GO
CREATE TABLE [tcu].[ProcessSchedule] (
	[ProcessId] [smallint] NOT NULL ,
	[ScheduleId] [tinyint] NOT NULL ,
	[ProcessSchedule] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StartTime] [smalldatetime] NOT NULL ,
	[EndTime] [smalldatetime] NOT NULL ,
	[Frequency] [int] NOT NULL ,
	[Attempts] [tinyint] NOT NULL ,
	[IsEnabled] [bit] NOT NULL ,
	[UsePriorDay] [bit] NOT NULL ,
	[UseNewestFile] [bit] NOT NULL ,
	[BeginOn] [smalldatetime] NULL ,
	[EndOn] [smalldatetime] NULL ,
	[RunTimeMedian] [tinyint] NOT NULL ,
	[RunTimeStdDev] [tinyint] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ProcessSchedule] PRIMARY KEY  CLUSTERED 
	(
		[ProcessId],
		[ScheduleId]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_ProcessSchedule_Frequency] CHECK ([Frequency]>(0)),
	CONSTRAINT [CK_ProcessSchedule_RunTimeMedian] CHECK ([RunTimeMedian]>(0)),
	CONSTRAINT [CK_ProcessSchedule_RunTimeStdDev] CHECK ([RunTimeStdDev]>(0)),
	CONSTRAINT [CK_ProcessSchedule_ScheduleTimes] CHECK ((CONVERT([int],[StartTime],(0))=(0) OR CONVERT([int],[StartTime],(0))=(1)) AND (CONVERT([int],[EndTime],(0))=(0) OR CONVERT([int],[EndTime],(0))=(1)) AND CONVERT([float],[EndTime],(0))>=CONVERT([float],[StartTime],(0)))
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Process] ON [tcu].[ProcessSchedule]([ProcessId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ScheduleId] ON [tcu].[ProcessSchedule]([ScheduleId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_StartTime] ON [tcu].[ProcessSchedule]([StartTime]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EndTime] ON [tcu].[ProcessSchedule]([EndTime]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Frequency] ON [tcu].[ProcessSchedule]([Frequency]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsEnabled] ON [tcu].[ProcessSchedule]([IsEnabled]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_UsePriorDay] ON [tcu].[ProcessSchedule]([UsePriorDay]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_UseNewestFile] ON [tcu].[ProcessSchedule]([UseNewestFile]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BeginOn] ON [tcu].[ProcessSchedule]([BeginOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EndOn] ON [tcu].[ProcessSchedule]([EndOn]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSchedule].[Attempts]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessSchedule].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessSchedule].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSchedule].[IsEnabled]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[ProcessSchedule].[RunTimeMedian]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[ProcessSchedule].[RunTimeStdDev]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSchedule].[UseNewestFile]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSchedule].[UsePriorDay]'
GO
setuser
GO
GRANT  SELECT  ON [tcu].[ProcessSchedule]  TO [wa_HelpDesk]
GO