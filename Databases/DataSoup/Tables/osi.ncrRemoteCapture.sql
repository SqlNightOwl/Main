use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncrRemoteCapture]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ncrRemoteCapture]
GO
CREATE TABLE [osi].[ncrRemoteCapture] (
	[RemoteCaptureId] [int] IDENTITY (1, 1) NOT NULL ,
	[CaptureOn] [datetime] NOT NULL ,
	[RecordType] [tinyint] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[RTN] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FedDistrict] [tinyint] NOT NULL ,
	[MerchantId] [bigint] NOT NULL ,
	[ClearingCategoryCode] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Amount] [money] NOT NULL ,
	[TransactionType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Sequence] [int] NOT NULL ,
	[DepositBy] [bigint] NULL ,
	[DepositAccount] [bigint] NULL ,
	[LoadedOn] [datetime] NOT NULL ,
	[RunId] [int] NOT NULL ,
	[ProcessStatus] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_ncrRemoteCapture] PRIMARY KEY  CLUSTERED 
	(
		[RemoteCaptureId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TransactionRunAccount] ON [osi].[ncrRemoteCapture]([RunId], [TransactionType], [AccountNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ncrRemoteCapture].[DepositAccount]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ncrRemoteCapture].[DepositBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ncrRemoteCapture].[LoadedOn]'
GO
setuser
GO