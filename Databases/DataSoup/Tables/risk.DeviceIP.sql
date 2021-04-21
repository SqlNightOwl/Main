use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[DeviceIP]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[DeviceIP]
GO
CREATE TABLE [risk].[DeviceIP] (
	[DeviceId] [int] NOT NULL ,
	[IP] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_DeviceIP] PRIMARY KEY  CLUSTERED 
	(
		[DeviceId],
		[IP]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[DeviceIP].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[DeviceIP].[CreatedOn]'
GO
setuser
GO