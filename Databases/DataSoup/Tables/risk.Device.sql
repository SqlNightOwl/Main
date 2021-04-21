use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Device]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[Device]
GO
CREATE TABLE [risk].[Device] (
	[DeviceId] [int] IDENTITY (1, 1) NOT NULL ,
	[Device] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ExtendedName] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DeviceType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AssignedTo] [int] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Device] PRIMARY KEY  CLUSTERED 
	(
		[DeviceId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Device] ON [risk].[Device]([Device]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Device].[AssignedTo]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Device].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Device].[CreatedOn]'
GO
setuser
GO