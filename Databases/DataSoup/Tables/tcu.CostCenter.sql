use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[CostCenter]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[CostCenter]
GO
CREATE TABLE [tcu].[CostCenter] (
	[CostCenter] [smallint] NOT NULL ,
	[CostCenterName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ManagerNumber] [int] NULL ,
	[ParentCostCenter] [smallint] NULL ,
	[IsFinancial] [bit] NOT NULL ,
	[IsActive] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_CostCenter] PRIMARY KEY  CLUSTERED 
	(
		[CostCenter]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_CostCenter] ON [tcu].[CostCenter]([CostCenterName]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[CostCenter].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[CostCenter].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[CostCenter].[IsActive]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CostCenter].[IsFinancial]'
GO
setuser
GO