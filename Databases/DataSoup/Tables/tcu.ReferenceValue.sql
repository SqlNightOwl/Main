use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ReferenceValue]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ReferenceValue]
GO
CREATE TABLE [tcu].[ReferenceValue] (
	[ReferenceValueId] [int] IDENTITY (1000, 1) NOT NULL ,
	[ReferenceId] [int] NOT NULL ,
	[ReferenceCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ReferenceValue] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Sequence] [smallint] NOT NULL ,
	[Description] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ExtendedData1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ExtendedData2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ExtendedData3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ParentValueId] [int] NULL ,
	[IsEnabled] [bit] NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_ReferenceValue] PRIMARY KEY  CLUSTERED 
	(
		[ReferenceId],
		[ReferenceCode]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_ReferenceValue] ON [tcu].[ReferenceValue]([ReferenceValueId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_ReferenceCode] ON [tcu].[ReferenceValue]([ReferenceCode]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Reference] ON [tcu].[ReferenceValue]([ReferenceId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsEnabled] ON [tcu].[ReferenceValue]([ReferenceValue]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ReferenceValue] ON [tcu].[ReferenceValue]([ReferenceValue]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Sequence] ON [tcu].[ReferenceValue]([Sequence]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ReferenceValue].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ReferenceValue].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[ReferenceValue].[IsEnabled]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[ReferenceValue].[Sequence]'
GO
setuser
GO