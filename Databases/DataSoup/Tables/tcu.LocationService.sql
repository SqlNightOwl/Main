use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationService]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[LocationService]
GO
CREATE TABLE [tcu].[LocationService] (
	[LocationId] [int] NOT NULL ,
	[ServiceTypeId] [int] NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[Updatedby] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_LocationService] PRIMARY KEY  CLUSTERED 
	(
		[LocationId],
		[ServiceTypeId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [Location_FK] ON [tcu].[LocationService]([LocationId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[LocationService].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[LocationService].[CreatedOn]'
GO
setuser
GO