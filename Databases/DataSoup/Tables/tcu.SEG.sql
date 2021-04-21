use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[SEG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[SEG]
GO
CREATE TABLE [tcu].[SEG] (
	[SegId] [int] IDENTITY (1, 1) NOT NULL ,
	[SegNumber] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SEG] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SegType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AKA] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[IsOpen] [bit] NOT NULL ,
	[StockSymbol] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AccountNumberBase] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AccountNumberFamily] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AccountNumberCheckDigit] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_SEG] PRIMARY KEY  CLUSTERED 
	(
		[SegId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_SegNumber] ON [tcu].[SEG]([SegNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_SEG] ON [tcu].[SEG]([SEG]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsOpen] ON [tcu].[SEG]([IsOpen]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_SegType] ON [tcu].[SEG]([SegType]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[SEG].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[SEG].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[SEG].[IsOpen]'
GO
setuser
GO