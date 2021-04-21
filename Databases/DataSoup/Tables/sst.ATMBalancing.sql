use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancing]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[ATMBalancing]
GO
CREATE TABLE [sst].[ATMBalancing] (
	[Record] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_ATMBalancing] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO