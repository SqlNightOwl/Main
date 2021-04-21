use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[SSRSReportUsage]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ops].[SSRSReportUsage]
GO
CREATE TABLE [ops].[SSRSReportUsage] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[ObjectName] [sysname] NOT NULL ,
	[UserId] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RunOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_SSRSReportUsage] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO