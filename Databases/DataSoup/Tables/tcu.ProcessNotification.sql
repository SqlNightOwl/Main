use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessNotification]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessNotification]
GO
CREATE TABLE [tcu].[ProcessNotification] (
	[ProcessId] [smallint] NOT NULL ,
	[MessageTypes] [tinyint] NOT NULL ,
	[Recipient] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ProcessNotification] PRIMARY KEY  CLUSTERED 
	(
		[ProcessId],
		[Recipient]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ProcessMessageTypes] ON [tcu].[ProcessNotification]([ProcessId], [MessageTypes]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_MessageTypes] ON [tcu].[ProcessNotification]([MessageTypes]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Recipient] ON [tcu].[ProcessNotification]([Recipient]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessNotification].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessNotification].[CreatedOn]'
GO
setuser
GO