use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOffFinal]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[ChargeOffFinal]
GO
CREATE TABLE [risk].[ChargeOffFinal] (
	[LoadedOn] [datetime] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[MinorCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_ChargeOffFinal] PRIMARY KEY  CLUSTERED 
	(
		[LoadedOn],
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LoadedOn] ON [risk].[ChargeOffFinal]([LoadedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MinorCd] ON [risk].[ChargeOffFinal]([MinorCd]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[ChargeOffFinal].[LoadedOn]'
GO
setuser
GO