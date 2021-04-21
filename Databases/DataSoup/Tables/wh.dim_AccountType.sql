use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_AccountType]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_AccountType]
GO
CREATE TABLE [wh].[dim_AccountType] (
	[AccountTypeId] [smallint] IDENTITY (1, 1) NOT NULL ,
	[CategoryCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Category] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MajorTypeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MajorType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MinorTypeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MinorType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CustomDesc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EffectiveOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_dim_AccountType] PRIMARY KEY  CLUSTERED 
	(
		[AccountTypeId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_AccountType] ON [wh].[dim_AccountType]([MajorTypeCd], [MinorTypeCd]) ON [PRIMARY]
GO