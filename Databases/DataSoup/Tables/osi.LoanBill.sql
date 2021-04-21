use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[LoanBill]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[LoanBill]
GO
CREATE TABLE [osi].[LoanBill] (
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[Page] [int] NOT NULL ,
	[ReportType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_LoanBill_ReportType] DEFAULT ('EXC'),
	[Detail] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_LoanBill] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	) WITH  FILLFACTOR = 100  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Page] ON [osi].[LoanBill]([Page]) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[LoanBill].[Page]'
GO
setuser
GO