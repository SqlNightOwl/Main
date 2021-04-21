use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessChain]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessChain]
GO
CREATE TABLE [tcu].[ProcessChain] (
	[ScheduledProcessId] [smallint] NOT NULL ,
	[ChainedProcessId] [smallint] NOT NULL ,
	[Sequence] [tinyint] NOT NULL ,
	[CancelChainOnError] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ProcessChain] PRIMARY KEY  CLUSTERED 
	(
		[ScheduledProcessId],
		[ChainedProcessId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [IX_ScheduledProcessSequence] ON [tcu].[ProcessChain]([ScheduledProcessId], [Sequence]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessChain].[CancelChainOnError]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessChain].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessChain].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[ProcessChain].[Sequence]'
GO
setuser
GO