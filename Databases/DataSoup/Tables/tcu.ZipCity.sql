use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ZipCity]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ZipCity]
GO
CREATE TABLE [tcu].[ZipCity] (
	[ZipCode] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[City] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_ZipCity] PRIMARY KEY  CLUSTERED 
	(
		[ZipCode],
		[State],
		[City]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ZipCode] ON [tcu].[ZipCity]([ZipCode]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_State] ON [tcu].[ZipCity]([State]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_City] ON [tcu].[ZipCity]([City]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO