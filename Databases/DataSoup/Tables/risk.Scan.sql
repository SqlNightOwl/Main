use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[Scan]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[Scan]
GO
CREATE TABLE [risk].[Scan] (
	[ScanId] [smallint] IDENTITY (1, 1) NOT NULL ,
	[Scan] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ScanType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ScanOn] [datetime] NULL ,
	[Company] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Description] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FileName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FileDate] [datetime] NULL ,
	[FileSize] [int] NULL ,
	[LoadedOn] [datetime] NULL ,
	[ParentId] [smallint] NULL ,
	[RequestorBy] [int] NULL ,
	[RequestedOn] [datetime] NULL ,
	[SubmittedBy] [int] NULL ,
	[SubmittedOn] [datetime] NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Scan] PRIMARY KEY  CLUSTERED 
	(
		[ScanId]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_Scan_ScanType] CHECK ([ScanType]='A' OR [ScanType]='E' OR [ScanType]='I')
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [IX_FileName] ON [risk].[Scan]([FileName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Scan].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Scan].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[Scan].[LoadedOn]'
GO
setuser
GO