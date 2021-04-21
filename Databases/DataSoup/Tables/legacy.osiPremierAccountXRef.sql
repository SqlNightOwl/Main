use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[legacy].[osiPremierAccountXRef]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [legacy].[osiPremierAccountXRef]
GO
CREATE TABLE [legacy].[osiPremierAccountXRef] (
	[MemberNumber] [bigint] NOT NULL ,
	[PremierTable] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PremierType] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PremierNumber] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OSIMbrNbr] [bigint] NOT NULL ,
	[OSIAcctNbr] [bigint] NOT NULL ,
	[CustomerType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CustomerId] [int] NOT NULL ,
	[OSIAcctType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MajorAcctTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MinorAcctTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_osiPremierAccountXRef] PRIMARY KEY  CLUSTERED 
	(
		[MemberNumber],
		[PremierTable],
		[PremierType],
		[PremierNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSIMbrNbr] ON [legacy].[osiPremierAccountXRef]([OSIMbrNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSIAcctNbr] ON [legacy].[osiPremierAccountXRef]([OSIAcctNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSICustomer] ON [legacy].[osiPremierAccountXRef]([CustomerType], [CustomerId]) ON [PRIMARY]
GO