use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[RiskRating]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[RiskRating]
GO
CREATE TABLE [risk].[RiskRating] (
	[RiskRating] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Constant] [decimal](17, 15) NULL ,
	[MinValue] [tinyint] NULL ,
	[MaxValue] [tinyint] NULL ,
	CONSTRAINT [PK_RiskRating] PRIMARY KEY  CLUSTERED 
	(
		[RiskRating]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO