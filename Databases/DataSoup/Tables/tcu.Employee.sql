use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Employee]
GO
CREATE TABLE [tcu].[Employee] (
	[EmployeeNumber] [int] NOT NULL ,
	[LastName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FirstName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PreferredName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HiredOn] [datetime] NULL ,
	[Email] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Department] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DepartmentCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JobTitle] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Telephone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Ext] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Fax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Gender] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Location] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LocationCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Pager] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Mobile] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PersonId] [int] NOT NULL ,
	[Classification] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ManagerNumber] [int] NULL ,
	[CostCenterCode] [smallint] NULL ,
	[CostCenter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EPMSCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PersNbr] [int] NOT NULL ,
	[IsDeleted] [bit] NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_Employee] PRIMARY KEY  NONCLUSTERED 
	(
		[EmployeeNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsDeleted] ON [tcu].[Employee]([IsDeleted]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EmployeeName] ON [tcu].[Employee]([LastName], [PreferredName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DepartmentCode] ON [tcu].[Employee]([DepartmentCode]) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Employee] ON [tcu].[Employee]([PersonId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_UpdatedBy] ON [tcu].[Employee]([UpdatedBy]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[Employee].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Employee].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Employee].[IsDeleted]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Employee].[PersNbr]'
GO
setuser
GO