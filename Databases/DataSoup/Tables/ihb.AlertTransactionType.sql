use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[AlertTransactionType]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[AlertTransactionType]
GO
CREATE TABLE [ihb].[AlertTransactionType] (
	[RtxnTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RtxnCatCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RtxnDesc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DebitDesc] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreditDesc] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_AlertTransactionType] PRIMARY KEY  CLUSTERED 
	(
		[RtxnTypCd]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_RtxnTypCdRtxnCatCd] ON [ihb].[AlertTransactionType]([RtxnTypCd], [RtxnCatCd]) ON [PRIMARY]
GO