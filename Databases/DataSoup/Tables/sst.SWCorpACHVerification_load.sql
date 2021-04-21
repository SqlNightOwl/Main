use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[SWCorpACHVerification_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[SWCorpACHVerification_load]
GO
CREATE TABLE [sst].[SWCorpACHVerification_load] (
	[Record] [char] (94) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO