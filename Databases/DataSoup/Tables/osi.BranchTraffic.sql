use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[BranchTraffic]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[BranchTraffic]
GO
CREATE TABLE [osi].[BranchTraffic] (
	[PostedOn] [datetime] NOT NULL ,
	[BranchNbr] [int] NOT NULL ,
	[CategoryCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Items] [int] NOT NULL ,
	[Amount] [money] NOT NULL ,
	CONSTRAINT [PK_BranchTraffic] PRIMARY KEY  CLUSTERED 
	(
		[PostedOn],
		[BranchNbr],
		[CategoryCd]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO