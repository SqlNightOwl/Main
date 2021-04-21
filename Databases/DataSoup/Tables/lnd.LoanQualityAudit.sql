use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[LoanQualityAudit]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [lnd].[LoanQualityAudit]
GO
CREATE TABLE [lnd].[LoanQualityAudit] (
	[RowID] [int] IDENTITY (1, 1) NOT NULL ,
	[OwnCD] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AcctNbr] [bigint] NOT NULL ,
	[MjAcctTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CurrMIAcctTypCD] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Product] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ContractDate] [datetime] NULL ,
	[CurrAcctStatCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LoanLimitYN] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CallDate] [datetime] NULL ,
	[CreditScore] [int] NULL ,
	[RiskRatingCD] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TaxOwnerNbr] [int] NULL ,
	[TaxOwnerCD] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PrimaryOwnerZipCD] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NoteOpenAmt] [money] NULL ,
	[NoteIntRate] [decimal](9, 6) NULL ,
	[NoteBal] [money] NULL ,
	[OwnerName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OwnerSortName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OriginatingPerson] [varchar] (43) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LoanOfficersNbr] [int] NULL ,
	[LoanOfficer] [varchar] (44) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OEMPRole] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[SIGNRole] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MemberAgreeNbr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IsEmployee] [bit] NULL ,
	[LoadOn] [datetime] NOT NULL ,
	[TotalPI] [money] NULL ,
	[PmtMethCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreditLimitAmt] [money] NULL ,
	CONSTRAINT [PK_LoanQualityAudit] PRIMARY KEY  CLUSTERED 
	(
		[RowID]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ContractDate] ON [lnd].[LoanQualityAudit]([ContractDate]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CurrAcctStatCd] ON [lnd].[LoanQualityAudit]([CurrAcctStatCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MiAcctTypCd] ON [lnd].[LoanQualityAudit]([CurrMIAcctTypCD]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MjAcctTypCd] ON [lnd].[LoanQualityAudit]([MjAcctTypCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AcctNbr] ON [lnd].[LoanQualityAudit]([AcctNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LoanLimitYN] ON [lnd].[LoanQualityAudit]([LoanLimitYN]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LoanOfficersNbr] ON [lnd].[LoanQualityAudit]([LoanOfficersNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LoadOn] ON [lnd].[LoanQualityAudit]([LoadOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_PrimaryOwnerZipCd] ON [lnd].[LoanQualityAudit]([PrimaryOwnerZipCD]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Product] ON [lnd].[LoanQualityAudit]([Product]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TaxOwnerNbr] ON [lnd].[LoanQualityAudit]([TaxOwnerNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TotalPI] ON [lnd].[LoanQualityAudit]([TotalPI]) ON [PRIMARY]
GO