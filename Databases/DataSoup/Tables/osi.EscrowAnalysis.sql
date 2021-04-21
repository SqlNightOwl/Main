use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowAnalysis]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[EscrowAnalysis]
GO
CREATE TABLE [osi].[EscrowAnalysis] (
	[Record] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Row] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_EscrowAnalysis] PRIMARY KEY  CLUSTERED 
	(
		[Row]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO