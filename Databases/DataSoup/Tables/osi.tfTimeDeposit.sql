use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfTimeDeposit]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[tfTimeDeposit]
GO
CREATE TABLE [osi].[tfTimeDeposit] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[Record] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MajorCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MinorCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FundSource] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Account] [bigint] NOT NULL ,
	[Amount] [money] NOT NULL ,
	[IsRetirement] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MinorDesc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Branch] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OrigEmpl] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AcctGrpNbr] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_tf_TimeDeposit] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Account] ON [osi].[tfTimeDeposit]([Account]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountType] ON [osi].[tfTimeDeposit]([MajorCd], [MinorCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsRetirement] ON [osi].[tfTimeDeposit]([IsRetirement]) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[tfTimeDeposit].[Account]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[tfTimeDeposit].[Amount]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[tfTimeDeposit].[FundSource]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[tfTimeDeposit].[MajorCd]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[tfTimeDeposit].[MinorCd]'
GO
setuser
GO