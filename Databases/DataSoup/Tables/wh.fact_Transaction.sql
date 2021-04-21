use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[fact_Transaction]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[fact_Transaction]
GO
CREATE TABLE [wh].[fact_Transaction] (
	[TransactionId] [int] IDENTITY (-2147483648, 1) NOT NULL ,
	[CustomerTypeCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CustomerNbr] [int] NOT NULL ,
	[AccountNbr] [bigint] NOT NULL ,
	[AccountTypeId] [smallint] NOT NULL ,
	[TransactionTypeId] [smallint] NOT NULL ,
	[TransactionSourceId] [tinyint] NOT NULL ,
	[AccountStatusId] [tinyint] NOT NULL ,
	[MerchantId] [int] NULL ,
	[TransactionNumber] [int] NULL ,
	[TransactionAmount] [money] NOT NULL ,
	[ApplicationNbr] [int] NULL ,
	[TraceNbr] [bigint] NULL ,
	[BranchNbr] [int] NULL ,
	[CashBoxNbr] [int] NULL ,
	[NetworkNodeNbr] [int] NULL ,
	[TellerNbr] [int] NULL ,
	[NetworkCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TerminalId] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OriginalPostDateId] [int] NULL ,
	[PostDateId] [int] NULL ,
	[EffectiveDateId] [int] NULL ,
	[ActivityDateTimeId] [int] NULL ,
	[TimeUniqueExtn] [bigint] NULL ,
	[CardTxnNbr] [bigint] NULL ,
	[AgreeNbr] [int] NULL ,
	[MemberNbr] [tinyint] NULL ,
	[ISOTxnCd] [smallint] NULL ,
	CONSTRAINT [PK_fact_Transaction] PRIMARY KEY  CLUSTERED 
	(
		[TransactionId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CustomerAccount] ON [wh].[fact_Transaction]([AccountNbr], [CustomerNbr], [CustomerTypeCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Customer] ON [wh].[fact_Transaction]([CustomerNbr], [CustomerTypeCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountTransaction] ON [wh].[fact_Transaction]([AccountNbr], [TransactionNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountType] ON [wh].[fact_Transaction]([AccountTypeId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TransactionType] ON [wh].[fact_Transaction]([TransactionTypeId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TransactionSource] ON [wh].[fact_Transaction]([TransactionSourceId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountStatus] ON [wh].[fact_Transaction]([AccountStatusId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Merchant] ON [wh].[fact_Transaction]([MerchantId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Branch] ON [wh].[fact_Transaction]([BranchNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OriginalPostDate] ON [wh].[fact_Transaction]([OriginalPostDateId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_PostDate] ON [wh].[fact_Transaction]([PostDateId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EffectiveDate] ON [wh].[fact_Transaction]([EffectiveDateId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ActivityDateTime] ON [wh].[fact_Transaction]([ActivityDateTimeId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TellerNbr] ON [wh].[fact_Transaction]([TellerNbr]) ON [PRIMARY]
GO