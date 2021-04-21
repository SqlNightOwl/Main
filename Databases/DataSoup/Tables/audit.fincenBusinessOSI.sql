use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenBusinessOSI]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [audit].[fincenBusinessOSI]
GO
CREATE TABLE [audit].[fincenBusinessOSI] (
	[OrgName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Zip] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MemberNumber] [bigint] NULL ,
	[TaxId] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[OrgNumber] [int] NOT NULL ,
	[OrgNameCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO