use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwimDetail]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessSwimDetail]
GO
CREATE TABLE [tcu].[ProcessSwimDetail] (
	[ProcessSwimDetailId] [int] IDENTITY (1, 1) NOT NULL ,
	[RunId] [int] NOT NULL ,
	[ProcessId] [smallint] NOT NULL ,
	[EffectiveOn] [datetime] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[Amount] [money] NOT NULL ,
	[Items] [int] NOT NULL ,
	[FundTypeCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FundTypeDetailCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TransactionCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TransactionDescription] [char] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ClearingCategoryCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TraceNumber] [int] NULL ,
	[CashBox] [int] NULL ,
	[IsComplete] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_ProcessSwimDetail] PRIMARY KEY  CLUSTERED 
	(
		[ProcessSwimDetailId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RunProcess] ON [tcu].[ProcessSwimDetail]([RunId], [ProcessId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [FK_Process] ON [tcu].[ProcessSwimDetail]([ProcessId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_CreatedOn] ON [tcu].[ProcessSwimDetail]([CreatedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsComplete] ON [tcu].[ProcessSwimDetail]([IsComplete]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessSwimDetail].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessSwimDetail].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSwimDetail].[IsComplete]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSwimDetail].[Items]'
GO
setuser
GO