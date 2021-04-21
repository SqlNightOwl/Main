use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[cnsReport]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[cnsReport]
GO
CREATE TABLE [osi].[cnsReport] (
	[Record] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_cnsReport] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO