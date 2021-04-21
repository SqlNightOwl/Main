use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[acct].[PurchaseCard]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [acct].[PurchaseCard]
GO
CREATE TABLE [acct].[PurchaseCard] (
	[AccountCd] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Amount] [money] NOT NULL ,
	[TransactionCd] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ExpenseDesc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OtherType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PaymentType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IsPersonal] [bit] NULL ,
	[ReportOn] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FirstName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LastName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TransactionDesc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Vendor] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ReimbursementType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[LoadedOn] [datetime] NOT NULL ,
	[GLAccountOverride] [int] NULL ,
	CONSTRAINT [PK_PurchaseCard] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'acct'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[PurchaseCard].[IsPersonal]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[PurchaseCard].[LoadedOn]'
GO
setuser
GO