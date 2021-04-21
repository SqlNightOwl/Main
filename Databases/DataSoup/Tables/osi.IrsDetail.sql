use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetail]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[IrsDetail]
GO
CREATE TABLE [osi].[IrsDetail] (
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[IrsReportId] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_IrsDetail_IrsReportId] DEFAULT ('+'),
	[RowType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_IrsDetail_RowType] DEFAULT ('B'),
	[AccountNumber] [bigint] NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[TaxId] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[City] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Zip] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Amount1] [bigint] NOT NULL ,
	[Amount2] [bigint] NOT NULL ,
	[Amount3] [bigint] NOT NULL ,
	[Amount4] [bigint] NOT NULL ,
	[Amount5] [bigint] NOT NULL ,
	[Amount6] [bigint] NOT NULL ,
	[Amount7] [bigint] NOT NULL ,
	[Amount8] [bigint] NOT NULL ,
	[Amount9] [bigint] NOT NULL ,
	[AmountA] [bigint] NOT NULL ,
	[AmountB] [bigint] NOT NULL ,
	[AmountC] [bigint] NOT NULL ,
	[Detail] [char] (748) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_IrsDetail] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Report] ON [osi].[IrsDetail]([IrsReportId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IrsReportRowType] ON [osi].[IrsDetail]([IrsReportId], [RowType]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [osi].[IrsDetail]([AccountNumber]) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[AccountNumber]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsDetail].[Address]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount1]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount2]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount3]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount4]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount5]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount6]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount7]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount8]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[Amount9]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[AmountA]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[AmountB]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[AmountC]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsDetail].[City]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[IrsDetail].[MemberNumber]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsDetail].[State]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsDetail].[TaxId]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[IrsDetail].[Zip]'
GO
setuser
GO