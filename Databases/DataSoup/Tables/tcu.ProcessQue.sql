use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessQue]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessQue]
GO
CREATE TABLE [tcu].[ProcessQue] (
	[ProcessQueId] [int] IDENTITY (1, 1) NOT NULL ,
	[IsManualRun] [bit] NOT NULL ,
	[RunId] [int] NOT NULL ,
	[ProcessId] [smallint] NOT NULL ,
	[ScheduleId] [tinyint] NOT NULL ,
	[Process] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ProcessType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RunOn] [datetime] NOT NULL ,
	[StartedOn] [datetime] NULL ,
	[Warnings] [tinyint] NOT NULL ,
	[ScheduledBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_ProcesQue] PRIMARY KEY  CLUSTERED 
	(
		[ProcessQueId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_ProcesQue] ON [tcu].[ProcessQue]([RunId], [ProcessId], [ScheduleId]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_ProcessSchedule] ON [tcu].[ProcessQue]([ProcessId], [ScheduleId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ScheduleId] ON [tcu].[ProcessQue]([ScheduleId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_StartedOn] ON [tcu].[ProcessQue]([StartedOn]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessQue].[Warnings]'
GO
setuser
GO