use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsAdjustment]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[IrsAdjustment]
GO
CREATE TABLE [osi].[IrsAdjustment] (
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[IrsReportId] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_osiIrsAdjustment_IrsReportId] DEFAULT ('+'),
	[RowType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[NumberId] [bigint] NOT NULL ,
	[IdType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Detail] [char] (748) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IsAdjusted] [bit] NOT NULL ,
	[Amount1] [int] NOT NULL ,
	[Amount2] [int] NOT NULL ,
	[Amount3] [int] NOT NULL ,
	[Amount4] [int] NOT NULL ,
	[Amount5] [int] NOT NULL ,
	[Amount6] [int] NOT NULL ,
	[Amount7] [int] NOT NULL ,
	[Amount8] [int] NOT NULL ,
	[Amount9] [int] NOT NULL ,
	[AmountA] [int] NOT NULL ,
	[AmountB] [int] NOT NULL ,
	[AmountC] [int] NOT NULL ,
	CONSTRAINT [PK_IrsAdjustment] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	) WITH  FILLFACTOR = 100  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IrsReportRowType] ON [osi].[IrsAdjustment]([IrsReportId], [RowType], [RowId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_NumberTypeAndId] ON [osi].[IrsAdjustment]([IrsReportId], [IdType], [NumberId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount1]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount2]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount3]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount4]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount5]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount6]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount7]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount8]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[Amount9]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[AmountA]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[AmountB]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[AmountC]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsAdjustment].[IdType]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[IsAdjusted]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsAdjustment].[NumberId]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsAdjustment].[RowType]'
GO
setuser
GO