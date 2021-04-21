use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[BusinessFee]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[BusinessFee]
GO
CREATE TABLE [ihb].[BusinessFee] (
	[Period] [int] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[Service] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Items] [int] NOT NULL ,
	[Fee] [smallmoney] NOT NULL ,
	[RunId] [int] NOT NULL ,
	[Status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_BusinessFee_Status] DEFAULT ('Loaded'),
	[LoadedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_BusinessFee] PRIMARY KEY  CLUSTERED 
	(
		[Period],
		[AccountNumber],
		[Service]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'ihb'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[BusinessFee].[Fee]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[BusinessFee].[LoadedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_PeriodCurrent]', N'[BusinessFee].[Period]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[BusinessFee].[RunId]'
GO
setuser
GO