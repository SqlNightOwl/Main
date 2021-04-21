use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[LoanBillMortgage]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[LoanBillMortgage]
GO
CREATE TABLE [osi].[LoanBillMortgage] (
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[Detail] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_LoanBillMortgage] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	) WITH  FILLFACTOR = 100  ON [PRIMARY] 
) ON [PRIMARY]
GO