use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwim]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessSwim]
GO
CREATE TABLE [tcu].[ProcessSwim] (
	[ProcessId] [smallint] NOT NULL ,
	[CashBox] [int] NOT NULL CONSTRAINT [DF_ProcessSwim_CashBox] DEFAULT ((33)),
	[FundTypeCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ProcessSwim_FundTypeCd] DEFAULT ('EL'),
	[FundTypeDetailCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ProcessSwim_FundTypeDetailCd] DEFAULT ('INTR'),
	[TransactionCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ProcessSwim_TransactionCd] DEFAULT ('DEPD'),
	[TransactionDescription] [char] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ClearingCategoryCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ProcessSwim_ClearingCategoryCd] DEFAULT ('IMED'),
	[HasTraceNumber] [bit] NOT NULL ,
	[GLOffsetAccount] [bigint] NOT NULL ,
	[GLOffsetTransactionCd] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[GLOffsetDescription] [char] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ProcessSwim] PRIMARY KEY  CLUSTERED 
	(
		[ProcessId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessSwim].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessSwim].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSwim].[GLOffsetAccount]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ProcessSwim].[HasTraceNumber]'
GO
setuser
GO