use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Compromise]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[Compromise]
GO
CREATE TABLE [risk].[Compromise] (
	[CompromiseId] [int] IDENTITY (1, 1) NOT NULL ,
	[CompromisePrefix] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Compromise] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ReceivedOn] [datetime] NOT NULL ,
	[BeginOn] [datetime] NULL ,
	[EndOn] [datetime] NULL ,
	[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_Compromise] PRIMARY KEY  CLUSTERED 
	(
		[CompromiseId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Compromise] ON [risk].[Compromise]([CompromisePrefix]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Compromise].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[Compromise].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[Compromise].[ReceivedOn]'
GO
setuser
GO
GRANT  REFERENCES ,  SELECT ,  UPDATE ,  INSERT  ON [risk].[Compromise]  TO [wa_CompromiseCards]
GO