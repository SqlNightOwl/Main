use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[ExperianHistory]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [lnd].[ExperianHistory]
GO
CREATE TABLE [lnd].[ExperianHistory] (
	[TaxId] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ScoreOn] [datetime] NOT NULL ,
	[FICOScore] [smallint] NULL ,
	[MDSScore] [smallint] NULL ,
	CONSTRAINT [PK_ExperianHistory] PRIMARY KEY  CLUSTERED 
	(
		[TaxId],
		[ScoreOn]
	) WITH  FILLFACTOR = 80  ON [PRIMARY] 
) ON [PRIMARY]
GO