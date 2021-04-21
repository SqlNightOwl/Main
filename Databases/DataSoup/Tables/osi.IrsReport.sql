use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsReport]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[IrsReport]
GO
CREATE TABLE [osi].[IrsReport] (
	[IrsReportId] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IrsReport] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FileName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ReportByMemberNumber] [bit] NOT NULL ,
	CONSTRAINT [PK_IrsReport] PRIMARY KEY  CLUSTERED 
	(
		[IrsReportId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_osiIrsReport] ON [osi].[IrsReport]([IrsReport]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO