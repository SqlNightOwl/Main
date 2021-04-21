use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServAccount]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[BankServAccount]
GO
CREATE TABLE [sst].[BankServAccount] (
	[OsiCustomerId] [int] NOT NULL ,
	[OsiCustomerType] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[Institution] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_BankServ_Account_Institution] DEFAULT ('01'),
	[CostCenter] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_BankServ_Account_CostCenter] DEFAULT ('9000'),
	[Branch] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_BankServ_Account_Branch] DEFAULT ('003'),
	[AccountName1] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountName2] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AddressLine1] [char] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AddressLine2] [char] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CityName] [char] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StateCode] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ZipCode] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Phone] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Fax] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Email] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CustomerId] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountType] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AnalyzedFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Department] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_BankServ_Account_Department] DEFAULT ('Acct1'),
	[HoldFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FrozenFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LockedFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[WaiveFeeFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_BankServ_Account_WaiveFeeFlag] DEFAULT ('N'),
	[AccountBalance] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BankServAccountId] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_BankServAccount] PRIMARY KEY  CLUSTERED 
	(
		[BankServAccountId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [sst].[BankServAccount]([AccountNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CustomerAccount] ON [sst].[BankServAccount]([OsiCustomerId], [OsiCustomerType], [AccountNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OsiCustomerType] ON [sst].[BankServAccount]([OsiCustomerType]) ON [PRIMARY]
GO
setuser N'sst'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[AccountName1]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[AccountName2]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[AddressLine1]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[AddressLine2]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[CityName]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[Email]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[Fax]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[Phone]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[StateCode]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[BankServAccount].[ZipCode]'
GO
setuser
GO