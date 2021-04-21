use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_TransactionType]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_TransactionType]
GO
CREATE TABLE [wh].[dim_TransactionType] (
	[TransactionTypeId] [smallint] IDENTITY (1, 1) NOT NULL ,
	[TransactionTypeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TransactionType] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TransactionCategoryCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TransactionCategory] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_dim_TransactionType] PRIMARY KEY  CLUSTERED 
	(
		[TransactionTypeId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_TransactionType] ON [wh].[dim_TransactionType]([TransactionTypeCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TransactionCategoryCode] ON [wh].[dim_TransactionType]([TransactionCategoryCd]) ON [PRIMARY]
GO