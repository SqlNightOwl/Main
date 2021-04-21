use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdEStatementScript]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[mdEStatementScript]
GO
CREATE TABLE [osi].[mdEStatementScript] (
	[ScriptId] [int] IDENTITY (1, 1) NOT NULL ,
	[Script] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_mdEStatementScript] PRIMARY KEY  CLUSTERED 
	(
		[ScriptId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO