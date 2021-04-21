use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[CashManagementLog_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[CashManagementLog_load]
GO
CREATE TABLE [ihb].[CashManagementLog_load] (
	[BatchId] [int] NOT NULL ,
	[BatchOn] [datetime] NOT NULL ,
	[IsComplete] [bit] NOT NULL ,
	[Status] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO