use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenBusinessMaster]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [audit].[fincenBusinessMaster]
GO
CREATE TABLE [audit].[fincenBusinessMaster] (
	[TrackingNumber] [int] NOT NULL ,
	[BusinessName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DbaName] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Number] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[NumberType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Incorporated] [datetime] NULL ,
	[Street] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Country] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Phone] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BusinessNameCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DbaNameCode] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO