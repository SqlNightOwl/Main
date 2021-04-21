use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskAccount]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[eriskAccount]
GO
CREATE TABLE [risk].[eriskAccount] (
	[AcctNbr] [bigint] NOT NULL ,
	[CustomerCd] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MajorTypeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MinorTypeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StatusCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BranchOrgNbr] [int] NOT NULL ,
	[OpeningBalance] [decimal](15, 2) NOT NULL ,
	[AccountBalance] [decimal](15, 2) NOT NULL ,
	[AverageBalance] [decimal](15, 2) NOT NULL ,
	[EscrowBalance] [decimal](15, 2) NOT NULL ,
	[UnappliedBalance] [decimal](15, 2) NOT NULL ,
	[CreditLimit] [decimal](15, 2) NOT NULL ,
	[InterestRate] [decimal](7, 5) NOT NULL ,
	[MaturityDate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ContractDate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CloseDate] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CountryCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCd] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StateCd] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RevolverCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RiskRatingCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LoanQualityCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreditScore] [smallint] NOT NULL ,
	[PastDueAmount] [decimal](15, 2) NOT NULL ,
	[PastDueMonths] [smallint] NOT NULL ,
	[LoanLossCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PurposeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AmortizationTerm] [smallint] NOT NULL ,
	[MaxDelenquency] [smallint] NOT NULL ,
	[TaxId] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TexansPct] [decimal](7, 6) NOT NULL ,
	[NaicsCd] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RenewalCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FicsLoanNbr] [int] NOT NULL ,
	[EffectiveDate] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_eriskAccount] PRIMARY KEY  CLUSTERED 
	(
		[AcctNbr]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CustomerCd] ON [risk].[eriskAccount]([CustomerCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MajorTypeCd] ON [risk].[eriskAccount]([MajorTypeCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TaxId] ON [risk].[eriskAccount]([TaxId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FicsLoanNbr] ON [risk].[eriskAccount]([FicsLoanNbr]) ON [PRIMARY]
GO