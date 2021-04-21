use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenPeopleMaster]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [audit].[fincenPeopleMaster]
GO
CREATE TABLE [audit].[fincenPeopleMaster] (
	[TrackingNumber] [int] NOT NULL ,
	[LastName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FirstName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MiddleName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Suffix] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AliasLastName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AliasFirstName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AliasMiddleName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AliasSuffix] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Number] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NumberType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DOB] [datetime] NULL ,
	[Street] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Country] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Phone] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NameCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AliasCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO