use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Address]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Address]
GO
CREATE TABLE [tcu].[Address] (
	[AddressId] [int] IDENTITY (1, 1) NOT NULL ,
	[Address] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ZipCd] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LocationId] [int] NULL ,
	[AddressCd] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Latitude] [decimal](9, 6) NOT NULL ,
	[Longitude] [decimal](9, 6) NOT NULL ,
	[HasPublicAccess] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Address] PRIMARY KEY  CLUSTERED 
	(
		[AddressId]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_Address_ZipCd] CHECK (isnumeric([ZipCd])=(1))
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Address_AddressCd] ON [tcu].[Address]([AddressCd]) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Address] ON [tcu].[Address]([Address]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Location] ON [tcu].[Address]([LocationId]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Address].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Address].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[Address].[HasPublicAccess]'
GO
setuser
GO