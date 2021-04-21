use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Process]
GO
CREATE TABLE [tcu].[Process] (
	[ProcessId] [smallint] NOT NULL ,
	[Process] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ProcessType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ProcessCategory] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ProcessHandler] [sysname] NULL ,
	[ProcessOwner] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IncludeRunInfo] [bit] NOT NULL ,
	[SkipFederalHolidays] [bit] NOT NULL ,
	[SkipCompanyHolidays] [bit] NOT NULL ,
	[IsEnabled] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Process] PRIMARY KEY  CLUSTERED 
	(
		[ProcessId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_Process] CHECK (case [ProcessType] when 'OSI' then (1) else len([ProcessHandler]) end>(0)),
	CONSTRAINT [CK_Process_ProcessType] CHECK ([ProcessType]='ACH' OR ([ProcessType]='OSI' OR ([ProcessType]='SWM' OR ([ProcessType]='PRC' OR ([ProcessType]='FTP' OR [ProcessType]='DTS')))))
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Process] ON [tcu].[Process]([Process]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_ProcessType] ON [tcu].[Process]([ProcessType]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_ProcessCategory] ON [tcu].[Process]([ProcessCategory]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_ProcessHandler] ON [tcu].[Process]([ProcessHandler]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsEnabled] ON [tcu].[Process]([IsEnabled]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Process].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Process].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Process].[IncludeRunInfo]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Process].[IsEnabled]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Process].[SkipCompanyHolidays]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Process].[SkipFederalHolidays]'
GO
setuser
GO