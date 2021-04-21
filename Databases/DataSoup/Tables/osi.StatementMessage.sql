use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementMessage]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[StatementMessage]
GO
CREATE TABLE [osi].[StatementMessage] (
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[Record] [char] (126) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_StatementMessage] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO