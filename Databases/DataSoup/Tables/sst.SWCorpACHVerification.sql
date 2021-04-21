use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[SWCorpACHVerification]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[SWCorpACHVerification]
GO
CREATE TABLE [sst].[SWCorpACHVerification] (
	[FileName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FileDate] [int] NOT NULL ,
	[FileType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TransactionCode] [tinyint] NOT NULL ,
	[RTN] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountNumber] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TaxId] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CompanyName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Amount] [money] NOT NULL ,
	[LoadedOn] [datetime] NOT NULL ,
	CONSTRAINT [CK_SWCorpACHVerification_FileType] CHECK ([FileType]='WEB' OR ([FileType]='TEL' OR ([FileType]='RCK' OR ([FileType]='PPD' OR ([FileType]='POP' OR ([FileType]='PBR' OR ([FileType]='CTX' OR ([FileType]='CCD' OR ([FileType]='CBR' OR [FileType]='ARC')))))))))
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileName] ON [sst].[SWCorpACHVerification]([FileName]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileRecords] ON [sst].[SWCorpACHVerification]([FileDate], [FileType], [TransactionCode]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'sst'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[SWCorpACHVerification].[AccountNumber]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[SWCorpACHVerification].[Amount]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[SWCorpACHVerification].[CompanyName]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[SWCorpACHVerification].[LoadedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[SWCorpACHVerification].[RTN]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[SWCorpACHVerification].[TaxId]'
GO
setuser
GO