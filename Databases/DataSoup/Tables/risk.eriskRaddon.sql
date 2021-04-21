use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskRaddon]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[eriskRaddon]
GO
CREATE TABLE [risk].[eriskRaddon] (
	[LoanNumber] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ProductType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NoteBalance] [money] NOT NULL ,
	[InterestRate] [decimal](7, 5) NOT NULL ,
	[MaturityDate] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PurposeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StatusCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_LoanNumber] ON [risk].[eriskRaddon]([LoanNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO