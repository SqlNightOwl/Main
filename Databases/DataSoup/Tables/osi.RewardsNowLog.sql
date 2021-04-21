use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[RewardsNowLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[RewardsNowLog]
GO
CREATE TABLE [osi].[RewardsNowLog] (
	[DDA] [bigint] NOT NULL ,
	[Name1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Phone1] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CardNumber] [bigint] NOT NULL ,
	[Status] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TranDate] [datetime] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[TranCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TranAmt] [money] NOT NULL ,
	[ReversalTypCd] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Flag] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EffDate] [datetime] NOT NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_EffDate] ON [osi].[RewardsNowLog]([EffDate]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EffDateAccountNumber] ON [osi].[RewardsNowLog]([EffDate], [AccountNumber]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[RewardsNowLog].[EffDate]'
GO
setuser
GO