use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfIsiAccount]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[tfIsiAccount]
GO
CREATE TABLE [osi].[tfIsiAccount] (
	[FirstName] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LastName] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[State] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Zip] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Country] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Email] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Age] [tinyint] NOT NULL ,
	[PersNbr] [int] NOT NULL ,
	[AcctNbr] [bigint] NOT NULL ,
	[BalanceGTE100] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MjAcct] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MiAcct] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ContractDate] [datetime] NOT NULL ,
	[OptOut] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_tf_IsiAccount] PRIMARY KEY  CLUSTERED 
	(
		[PersNbr],
		[AcctNbr]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Zip] ON [osi].[tfIsiAccount]([Zip]) ON [PRIMARY]
GO