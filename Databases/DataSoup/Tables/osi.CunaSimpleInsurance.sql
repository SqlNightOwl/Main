use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[CunaSimpleInsurance]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[CunaSimpleInsurance]
GO
CREATE TABLE [osi].[CunaSimpleInsurance] (
	[Record] [varchar] (132) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Row] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_CunaSimpleInsurance] PRIMARY KEY  CLUSTERED 
	(
		[Row]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO