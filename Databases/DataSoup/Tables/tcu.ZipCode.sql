use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ZipCode]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ZipCode]
GO
CREATE TABLE [tcu].[ZipCode] (
	[ZipCode] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ZipCodeType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TimeZone] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[GMTOffset] [smallint] NOT NULL ,
	[ObservesDST] [bit] NOT NULL ,
	[Latitude] [decimal](9, 6) NOT NULL ,
	[Longitude] [decimal](9, 6) NOT NULL ,
	CONSTRAINT [PK_ZipCode] PRIMARY KEY  CLUSTERED 
	(
		[ZipCode]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_State] ON [tcu].[ZipCode]([State]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ZipCode].[GMTOffset]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ZipCode].[Latitude]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ZipCode].[Longitude]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ZipCode].[ObservesDST]'
GO
setuser
GO