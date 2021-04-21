use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_TransactionSource]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_TransactionSource]
GO
CREATE TABLE [wh].[dim_TransactionSource] (
	[TransactionSourceId] [tinyint] IDENTITY (1, 1) NOT NULL ,
	[TransactionSourceCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TransactionSource] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_dim_TransactionSource] PRIMARY KEY  CLUSTERED 
	(
		[TransactionSourceId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_TransactionSource] ON [wh].[dim_TransactionSource]([TransactionSourceCd]) ON [PRIMARY]
GO