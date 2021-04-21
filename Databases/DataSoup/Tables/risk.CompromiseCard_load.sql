use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[CompromiseCard_load]
GO
CREATE TABLE [risk].[CompromiseCard_load] (
	[CardNumber] [bigint] NOT NULL ,
	[Alert] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CompromiseId] [int] NOT NULL ,
	[AlertId] [int] NOT NULL ,
	CONSTRAINT [PK_CompromiseCard_load] PRIMARY KEY  CLUSTERED 
	(
		[Alert],
		[CardNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard_load].[AlertId]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard_load].[CompromiseId]'
GO
setuser
GO