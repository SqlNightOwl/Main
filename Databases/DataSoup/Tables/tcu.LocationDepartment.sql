use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationDepartment]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[LocationDepartment]
GO
CREATE TABLE [tcu].[LocationDepartment] (
	[LocationId] [int] NOT NULL ,
	[DepartmentCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Sequence] [tinyint] NOT NULL ,
	[group_code] [nvarchar] (85) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_LocatiionDepartment] PRIMARY KEY  CLUSTERED 
	(
		[DepartmentCode]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Location] ON [tcu].[LocationDepartment]([LocationId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LocationSequence] ON [tcu].[LocationDepartment]([LocationId], [Sequence]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[LocationDepartment].[Sequence]'
GO
setuser
GO