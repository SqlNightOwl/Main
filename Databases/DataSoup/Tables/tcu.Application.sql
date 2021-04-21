use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Application]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Application]
GO
CREATE TABLE [tcu].[Application] (
	[Application] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Description] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_Application] PRIMARY KEY  CLUSTERED 
	(
		[Application]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Application].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Application].[CreatedOn]'
GO
setuser
GO