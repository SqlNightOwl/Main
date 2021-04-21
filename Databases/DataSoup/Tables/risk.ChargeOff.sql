use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOff]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[ChargeOff]
GO
CREATE TABLE [risk].[ChargeOff] (
	[ChargeOffOn] [datetime] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[ARFS] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MajorCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MinorCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ShareAccount] [bigint] NOT NULL ,
	[OwnerNumber] [int] NOT NULL ,
	[OwnerCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ChargeOff_AccountType] DEFAULT ('L'),
	CONSTRAINT [PK_ChargeOff] PRIMARY KEY  CLUSTERED 
	(
		[ChargeOffOn],
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [risk].[ChargeOff]([AccountNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ARFS] ON [risk].[ChargeOff]([ARFS]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ShareAccount] ON [risk].[ChargeOff]([ShareAccount]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MajorCd] ON [risk].[ChargeOff]([MajorCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OwnerCd] ON [risk].[ChargeOff]([OwnerCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OwnerNumber] ON [risk].[ChargeOff]([OwnerNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountType] ON [risk].[ChargeOff]([AccountType]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[ChargeOff].[OwnerCd]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ChargeOff].[OwnerNumber]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ChargeOff].[ShareAccount]'
GO
setuser
GO