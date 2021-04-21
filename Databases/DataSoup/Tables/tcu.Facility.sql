use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Facility]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Facility]
GO
CREATE TABLE [tcu].[Facility] (
	[FacilityCd] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CompanyId] [int] NOT NULL ,
	[LocationId] [int] NOT NULL ,
	[Facility] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ZipCd] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Latitude] [decimal](9, 6) NOT NULL ,
	[Longitude] [decimal](9, 6) NOT NULL ,
	[HasPublicAccess] [bit] NOT NULL ,
	[IsActive] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Facility] PRIMARY KEY  CLUSTERED 
	(
		[FacilityCd]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_Address_ZipCd] CHECK (isnumeric([ZipCd])=(1))
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_LocationId] ON [tcu].[Facility]([LocationId]) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Facility] ON [tcu].[Facility]([Facility]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Facility].[CompanyId]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Facility].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Facility].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[Facility].[HasPublicAccess]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[Facility].[IsActive]'
GO
setuser
GO