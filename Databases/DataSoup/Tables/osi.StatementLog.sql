use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[StatementLog]
GO
CREATE TABLE [osi].[StatementLog] (
	[Period] [int] NOT NULL ,
	[Type] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[QueueId] [int] NOT NULL ,
	[Statements] [int] NOT NULL ,
	[Pages] [int] NOT NULL ,
	[FileSize] [int] NOT NULL ,
	[BeginOn] [datetime] NOT NULL ,
	[EndOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_StatementLog] PRIMARY KEY  CLUSTERED 
	(
		[Period],
		[Type],
		[QueueId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[StatementLog].[FileSize]'
GO
setuser
GO