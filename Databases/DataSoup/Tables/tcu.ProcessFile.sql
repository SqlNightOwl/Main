use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessFile]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessFile]
GO
CREATE TABLE [tcu].[ProcessFile] (
	[ProcessId] [smallint] NOT NULL ,
	[FileName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TargetFile] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AddDate] [bit] NOT NULL ,
	[IsRequired] [bit] NOT NULL ,
	[ApplName] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ApplFrequency] [int] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ProcessFile] PRIMARY KEY  CLUSTERED 
	(
		[ProcessId],
		[FileName]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplFrequency] ON [tcu].[ProcessFile]([ApplFrequency]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileName] ON [tcu].[ProcessFile]([FileName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplName] ON [tcu].[ProcessFile]([ApplName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TargetFile] ON [tcu].[ProcessFile]([TargetFile]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessFile].[AddDate]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessFile].[ApplFrequency]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessFile].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessFile].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessFile].[IsRequired]'
GO
setuser
GO