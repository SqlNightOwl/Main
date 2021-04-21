use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenPeopleOSI]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [audit].[fincenPeopleOSI]
GO
CREATE TABLE [audit].[fincenPeopleOSI] (
	[FirstName] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LastName] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CityName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StateCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCd] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MemberNumber] [bigint] NULL ,
	[TaxId] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DateBirth] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PersonNumber] [int] NOT NULL ,
	[NameCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO