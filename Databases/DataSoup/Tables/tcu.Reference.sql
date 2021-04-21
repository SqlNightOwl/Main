use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Reference]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Reference]
GO
CREATE TABLE [tcu].[Reference] (
	[ReferenceId] [int] IDENTITY (1, 1) NOT NULL ,
	[ReferenceObject] [varchar] (510) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Caption] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ValueType] [ut_ValueType] NOT NULL ,
	[IsEnabled] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Reference] PRIMARY KEY  CLUSTERED 
	(
		[ReferenceId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Reference] ON [tcu].[Reference]([ReferenceObject]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsEnabled] ON [tcu].[Reference]([IsEnabled]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Reference].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Reference].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[Reference].[IsEnabled]'
GO
EXEC sp_bindrule N'[dbo].[ck_ValueType]', N'[Reference].[ValueType]'
GO
EXEC sp_bindefault N'[dbo].[df_ValueType]', N'[Reference].[ValueType]'
GO
setuser
GO