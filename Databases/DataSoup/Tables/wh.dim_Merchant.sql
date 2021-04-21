use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_Merchant]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_Merchant]
GO
CREATE TABLE [wh].[dim_Merchant] (
	[MerchantId] [int] IDENTITY (1, 1) NOT NULL ,
	[MerchantCd] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Merchant] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCd] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CountryCd] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Company] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Industry] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TransactionCount] [int] NOT NULL ,
	CONSTRAINT [PK_dim_Merchant] PRIMARY KEY  CLUSTERED 
	(
		[MerchantId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_Merchant] ON [wh].[dim_Merchant]([MerchantCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Company] ON [wh].[dim_Merchant]([Company]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Industry] ON [wh].[dim_Merchant]([Industry]) ON [PRIMARY]
GO
setuser N'wh'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[dim_Merchant].[TransactionCount]'
GO
setuser
GO