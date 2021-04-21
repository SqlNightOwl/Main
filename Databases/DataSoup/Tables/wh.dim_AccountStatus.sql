use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_AccountStatus]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_AccountStatus]
GO
CREATE TABLE [wh].[dim_AccountStatus] (
	[AccountStatusId] [tinyint] IDENTITY (1, 1) NOT NULL ,
	[AccountStatusCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountStatus] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_dim_AccountStatus] PRIMARY KEY  CLUSTERED 
	(
		[AccountStatusId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_AccountStatus] ON [wh].[dim_AccountStatus]([AccountStatusCd]) ON [PRIMARY]
GO