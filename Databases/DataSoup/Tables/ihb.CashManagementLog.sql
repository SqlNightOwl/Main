use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[CashManagementLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[CashManagementLog]
GO
CREATE TABLE [ihb].[CashManagementLog] (
	[BatchId] [int] NOT NULL ,
	[BatchOn] [datetime] NOT NULL ,
	[IsComplete] [bit] NOT NULL ,
	[Status] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_CashManagementLog] PRIMARY KEY  CLUSTERED 
	(
		[BatchId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BatchOn] ON [ihb].[CashManagementLog]([BatchOn]) ON [PRIMARY]
GO