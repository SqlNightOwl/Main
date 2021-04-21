use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[AlertHeader]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[AlertHeader]
GO
CREATE TABLE [ihb].[AlertHeader] (
	[RequestType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RequestDate] [char] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RecordCount] [int] NOT NULL ,
	CONSTRAINT [PK_AlertHeader] PRIMARY KEY  CLUSTERED 
	(
		[RequestType]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO