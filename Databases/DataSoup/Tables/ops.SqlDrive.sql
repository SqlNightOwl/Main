use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[SqlDrive]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ops].[SqlDrive]
GO
CREATE TABLE [ops].[SqlDrive] (
	[Drive] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MbTotal] [int] NOT NULL ,
	[MbFree] [int] NOT NULL ,
	[PercentFree] AS (CONVERT([decimal](4,1),([MbFree]/CONVERT([float],[MbTotal],(0)))*(100),(0))) ,
	[Purpose] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_SqlDrive] PRIMARY KEY  CLUSTERED 
	(
		[Drive]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO