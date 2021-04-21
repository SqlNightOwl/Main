use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Location]
GO
CREATE TABLE [tcu].[Location] (
	[LocationId] [int] IDENTITY (0, 1) NOT NULL ,
	[Location] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LocationType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LocationSubType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LocationCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OrgNbr] [int] NOT NULL ,
	[AddressCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address1] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address2] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ZipCode] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Phone] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Fax] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TollFree] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ParentId] [int] NULL ,
	[ManagerId] [int] NULL ,
	[DepartmentCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PlayListId] [tinyint] NOT NULL ,
	[Region] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Directions] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WebNotice] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Latitude] [decimal](9, 6) NOT NULL ,
	[Longitude] [decimal](9, 6) NOT NULL ,
	[CashBox] [int] NOT NULL ,
	[DirectPostAcctNbr] [bigint] NOT NULL ,
	[IsActive] [bit] NOT NULL ,
	[HasPublicAccess] [bit] NOT NULL ,
	[AcceptsDeposits] [tinyint] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Location] PRIMARY KEY  CLUSTERED 
	(
		[LocationId]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_Location_Fax] CHECK (isnumeric(isnull([Fax],'0'))=(1)),
	CONSTRAINT [CK_Location_Phone] CHECK (isnumeric(isnull([Phone],'0'))=(1))
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Location] ON [tcu].[Location]([Location]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LocationType] ON [tcu].[Location]([LocationType]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LocationCode] ON [tcu].[Location]([LocationCode]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OrgNbr] ON [tcu].[Location]([OrgNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ZipCode] ON [tcu].[Location]([ZipCode]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ParentId] ON [tcu].[Location]([ParentId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ManagerId] ON [tcu].[Location]([ManagerId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_PlayListId] ON [tcu].[Location]([PlayListId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Latitude] ON [tcu].[Location]([Latitude]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Longitude] ON [tcu].[Location]([Longitude]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CashBox] ON [tcu].[Location]([CashBox]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DirectPostAcctNbr] ON [tcu].[Location]([DirectPostAcctNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_HasPublicAccess] ON [tcu].[Location]([HasPublicAccess]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[Location].[AcceptsDeposits]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[CashBox]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Location].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Location].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[DirectPostAcctNbr]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[HasPublicAccess]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[IsActive]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[Latitude]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[Longitude]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[OrgNbr]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Location].[PlayListId]'
GO
setuser
GO