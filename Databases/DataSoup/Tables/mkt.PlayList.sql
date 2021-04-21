use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[PlayList]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[PlayList]
GO
CREATE TABLE [mkt].[PlayList] (
	[PlayListId] [tinyint] NOT NULL ,
	[PlayList] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AspectRatio] [ut_AspectRatio] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_PlayList] PRIMARY KEY  CLUSTERED 
	(
		[PlayListId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_PlayList] ON [mkt].[PlayList]([PlayList]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[PlayList].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[PlayList].[CreatedOn]'
GO
setuser
GO