use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[ExperianHistory_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [lnd].[ExperianHistory_load]
GO
CREATE TABLE [lnd].[ExperianHistory_load] (
	[TaxId] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FICOScore] [smallint] NULL ,
	[MDSScore] [smallint] NULL 
) ON [PRIMARY]
GO