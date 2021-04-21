use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFilePlayList]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[FlashFilePlayList]
GO
CREATE TABLE [mkt].[FlashFilePlayList] (
	[PlayListId] [tinyint] NOT NULL ,
	[Sequence] [tinyint] NOT NULL ,
	[FlashFileId] [int] NOT NULL ,
	[IsEnabled] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_FlashFilePlayList] PRIMARY KEY  CLUSTERED 
	(
		[PlayListId],
		[Sequence]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_PlayList] ON [mkt].[FlashFilePlayList]([PlayListId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [FK_FlashFile] ON [mkt].[FlashFilePlayList]([FlashFileId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[FlashFilePlayList].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[FlashFilePlayList].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[FlashFilePlayList].[IsEnabled]'
GO
setuser
GO