use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFile]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[FlashFile]
GO
CREATE TABLE [mkt].[FlashFile] (
	[FlashFileId] [int] IDENTITY (1, 1) NOT NULL ,
	[FlashFile] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RunLength] [tinyint] NOT NULL ,
	[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EffectiveOn] [datetime] NULL ,
	[ExpiresOn] [datetime] NULL ,
	[IsAvailable] [bit] NOT NULL ,
	[AspectRatio] [ut_AspectRatio] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_FlashFile] PRIMARY KEY  CLUSTERED 
	(
		[FlashFileId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_FlashFile_RunDates] CHECK (case when coalesce([EffectiveOn],[ExpiresOn],getdate())<=coalesce([ExpiresOn],[EffectiveOn],getdate()) then (1) else (0) end=(1)),
	CONSTRAINT [CK_FlashFile_RunLength] CHECK ([RunLength]>(0))
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_FlashFile] ON [mkt].[FlashFile]([FlashFile]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindrule N'[dbo].[ck_AspectRatio]', N'[FlashFile].[AspectRatio]'
GO
EXEC sp_bindefault N'[dbo].[df_AspectRatio]', N'[FlashFile].[AspectRatio]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[FlashFile].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[FlashFile].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[FlashFile].[IsAvailable]'
GO
setuser
GO