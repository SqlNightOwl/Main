use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseAlert]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[CompromiseAlert]
GO
CREATE TABLE [risk].[CompromiseAlert] (
	[AlertId] [int] IDENTITY (1, 1) NOT NULL ,
	[Alert] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CompromiseId] [int] NOT NULL ,
	[NoticeOn] [datetime] NULL ,
	[LoadedOn] [datetime] NULL ,
	[NumberOfCards] [int] NOT NULL ,
	[Notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_CompromiseAlert] PRIMARY KEY  CLUSTERED 
	(
		[AlertId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_CompromiseAlert] ON [risk].[CompromiseAlert]([Alert]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Compromise] ON [risk].[CompromiseAlert]([CompromiseId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LoadedOn] ON [risk].[CompromiseAlert]([LoadedOn]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[CompromiseAlert].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[CompromiseAlert].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseAlert].[NumberOfCards]'
GO
setuser
GO
GRANT  REFERENCES ,  SELECT ,  UPDATE  ON [risk].[CompromiseAlert]  TO [wa_CompromiseCards]
GO