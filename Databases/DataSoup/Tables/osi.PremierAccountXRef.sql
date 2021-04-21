use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[PremierAccountXRef]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[PremierAccountXRef]
GO
CREATE TABLE [osi].[PremierAccountXRef] (
	[MemberNumber] [bigint] NOT NULL ,
	[PremierTable] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PremierType] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PremierNumber] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OSIMbrNbr] [bigint] NOT NULL ,
	[OSIAcctNbr] [bigint] NOT NULL ,
	[CustomerType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CustomerId] [int] NOT NULL ,
	[OSIAcctType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_PremierAccountXRef_OSIAcctType] DEFAULT ('n/a'),
	[MajorAcctTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MinorAcctTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_PremierAccountXRef] PRIMARY KEY  CLUSTERED 
	(
		[MemberNumber],
		[PremierTable],
		[PremierType],
		[PremierNumber]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSIAcctNbr] ON [osi].[PremierAccountXRef]([OSIAcctNbr]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSIMbrNbr] ON [osi].[PremierAccountXRef]([OSIMbrNbr]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSICustomer] ON [osi].[PremierAccountXRef]([CustomerType], [CustomerId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO