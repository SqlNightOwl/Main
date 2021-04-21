use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[adGroupUser]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[adGroupUser]
GO
CREATE TABLE [tcu].[adGroupUser] (
	[samGroupName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[samUserName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EmployeeNumber] [int] NOT NULL ,
	[IsActive] [tinyint] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_adGroupUser] PRIMARY KEY  CLUSTERED 
	(
		[samGroupName],
		[samUserName]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_adGroup] ON [tcu].[adGroupUser]([samGroupName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [FK_adUser] ON [tcu].[adGroupUser]([samUserName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_EmployeeNumber] ON [tcu].[adGroupUser]([EmployeeNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[adGroupUser].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[adGroupUser].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[adGroupUser].[IsActive]'
GO
setuser
GO