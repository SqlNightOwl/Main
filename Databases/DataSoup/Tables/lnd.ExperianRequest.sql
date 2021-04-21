use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[ExperianRequest]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [lnd].[ExperianRequest]
GO
CREATE TABLE [lnd].[ExperianRequest] (
	[Customer] [varchar] (41) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CityName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StateCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCd] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TaxId] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO