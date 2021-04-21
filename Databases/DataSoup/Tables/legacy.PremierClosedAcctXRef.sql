use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[legacy].[PremierClosedAcctXRef]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [legacy].[PremierClosedAcctXRef]
GO
CREATE TABLE [legacy].[PremierClosedAcctXRef] (
	[SSN] [bigint] NULL ,
	[Name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ClosedDate] [datetime] NULL ,
	[Type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MemberNumber] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Balance] [money] NULL ,
	[Message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Txn] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TxnDate] [datetime] NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_PremierClosedAcctXRef] ON [legacy].[PremierClosedAcctXRef]([SSN], [ClosedDate]) ON [PRIMARY]
GO