use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskColonialLoan]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[eriskColonialLoan]
GO
CREATE TABLE [risk].[eriskColonialLoan] (
	[ID] [bigint] NOT NULL ,
	[LoanNumber] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LienType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[InvestorNumber] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CategoryNumber] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Payment] [money] NULL ,
	[CurrentBalance] [money] NULL ,
	[CurrentRate] [float] NULL ,
	[MaturityDate] [datetime] NULL ,
	[NextPaymentDate] [datetime] NULL ,
	[AppraisedValue] [money] NULL ,
	[FirstPaymentDueDate] [datetime] NULL ,
	[OriginationDate] [datetime] NULL ,
	[OriginalTerm] [smallint] NULL ,
	[LoanType] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PIConstant] [money] NULL ,
	[PIConstantDate] [datetime] NULL ,
	[NextInterestChange] [datetime] NULL ,
	[OrigPrinBalance] [money] NULL ,
	[City] [char] (28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Zip] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ColonialProductCode] [char] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EscrowBalance] [money] NULL ,
	[MonthlyEscrowPd] [money] NULL ,
	[PastDueAmount] [money] NULL ,
	[LateChgBalDue] [smallmoney] NULL 
) ON [PRIMARY]
GO