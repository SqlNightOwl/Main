use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[NetLendLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [lnd].[NetLendLog]
GO
CREATE TABLE [lnd].[NetLendLog] (
	[NetLendLogId] [int] IDENTITY (1, 1) NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[SSN] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Success] [bit] NOT NULL ,
	[RecordedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_NetLendLog] PRIMARY KEY  CLUSTERED 
	(
		[NetLendLogId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNumber] ON [lnd].[NetLendLog]([MemberNumber], [RecordedOn]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_SSN] ON [lnd].[NetLendLog]([SSN], [RecordedOn]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO