use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Notice]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[Notice]
GO
CREATE TABLE [osi].[Notice] (
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[Detail] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ApplName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FileName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Page] [int] NOT NULL ,
	[ReportType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Notice_ReportType] DEFAULT ('CNS'),
	CONSTRAINT [PK_Notice] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	) WITH  FILLFACTOR = 100  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplName] ON [osi].[Notice]([ApplName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Detail] ON [osi].[Notice]([Detail]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileName] ON [osi].[Notice]([FileName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Page] ON [osi].[Notice]([Page]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ReportType] ON [osi].[Notice]([ReportType]) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Notice].[Page]'
GO
setuser
GO