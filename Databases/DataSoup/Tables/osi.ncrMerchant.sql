use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncrMerchant]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ncrMerchant]
GO
CREATE TABLE [osi].[ncrMerchant] (
	[MerchantId] [bigint] NOT NULL ,
	[Merchant] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ClearingCategoryCode] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FedDistrict] [tinyint] NOT NULL ,
	[Tier] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ncrMerchant_Tier] DEFAULT ('Tier 1'),
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ncrMerchant] PRIMARY KEY  CLUSTERED 
	(
		[MerchantId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ncrMerchant].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ncrMerchant].[CreatedOn]'
GO
setuser
GO