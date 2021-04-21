use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[BoardReport]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[BoardReport]
GO
CREATE TABLE [ihb].[BoardReport] (
	[Period] [int] NOT NULL ,
	[ActiveUsers] [int] NOT NULL ,
	[BusinessUsers] [int] NOT NULL ,
	[ActiveUsersLast90Days] [int] NOT NULL ,
	[BusinessUsersLast90Days] [int] NOT NULL ,
	[BillPayUsers] [int] NOT NULL ,
	CONSTRAINT [PK_BoardReport] PRIMARY KEY  CLUSTERED 
	(
		[Period]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO