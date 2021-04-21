use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[VINtek]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [lnd].[VINtek]
GO
CREATE TABLE [lnd].[VINtek] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[RecordType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ETLAction] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AcctNbr] [bigint] NOT NULL ,
	[NewAcctNbr] [bigint] NULL ,
	[PropId] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PropYear] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PropMake] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PropModel] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DealerNbr] [bigint] NULL ,
	[Borrower] [varchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BorrowerNbr] [int] NOT NULL ,
	[CoBorrower] [varchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CoBorrowerNbr] [int] NULL ,
	[Address1] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address2] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StateCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCd] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AddrNbr] [int] NOT NULL ,
	[AddressUpdatedOn] [datetime] NOT NULL ,
	[ContractDate] [datetime] NOT NULL ,
	[MaturesOn] [datetime] NULL ,
	[TitleStateCd] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StatusCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PropVehicleOdometer] [int] NULL ,
	[CollateralType] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MemberNbr] [bigint] NOT NULL ,
	[LoadedOn] [datetime] NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_VINtek] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_VINtek] ON [lnd].[VINtek]([AcctNbr], [PropId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_PropId] ON [lnd].[VINtek]([PropId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BorrowerNbr] ON [lnd].[VINtek]([BorrowerNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CoBorrower] ON [lnd].[VINtek]([CoBorrowerNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AddrNbr] ON [lnd].[VINtek]([AddrNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LoadedOn] ON [lnd].[VINtek]([LoadedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNbr] ON [lnd].[VINtek]([MemberNbr]) ON [PRIMARY]
GO
setuser N'lnd'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[VINtek].[LoadedOn]'
GO
setuser
GO