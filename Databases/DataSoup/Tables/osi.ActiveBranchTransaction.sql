use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranchTransaction]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ActiveBranchTransaction]
GO
CREATE TABLE [osi].[ActiveBranchTransaction] (
	[TransactionId] [int] IDENTITY (1, 1) NOT NULL ,
	[Period] [int] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[TransactionNumber] [int] NOT NULL ,
	[SourceCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TypeCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BranchCd] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_ActiveBranchTransaction] PRIMARY KEY  CLUSTERED 
	(
		[TransactionId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BranchCd] ON [osi].[ActiveBranchTransaction]([BranchCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Period] ON [osi].[ActiveBranchTransaction]([Period]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [osi].[ActiveBranchTransaction]([AccountNumber]) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_AccountTransaction] ON [osi].[ActiveBranchTransaction]([AccountNumber], [TransactionNumber]) ON [PRIMARY]
GO