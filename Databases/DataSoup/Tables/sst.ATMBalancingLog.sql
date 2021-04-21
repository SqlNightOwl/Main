use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancingLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[ATMBalancingLog]
GO
CREATE TABLE [sst].[ATMBalancingLog] (
	[ReportOn] [datetime] NOT NULL ,
	[Terminal] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Withdrawal] [money] NOT NULL ,
	[Fee] [money] NOT NULL ,
	[NetWithdrawal] [money] NOT NULL ,
	[DepositSave] [money] NOT NULL ,
	[DepositCheck] [money] NOT NULL ,
	[DepositCrCard] [money] NOT NULL ,
	[DepositCrLine] [money] NOT NULL ,
	[Deposit] [money] NOT NULL ,
	CONSTRAINT [PK_ATMBalancingLog] PRIMARY KEY  CLUSTERED 
	(
		[ReportOn],
		[Terminal]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Terminal] ON [sst].[ATMBalancingLog]([Terminal]) ON [PRIMARY]
GO