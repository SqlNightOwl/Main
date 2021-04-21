use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[AlertTransaction]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[AlertTransaction]
GO
CREATE TABLE [ihb].[AlertTransaction] (
	[AlertTransactionId] [int] IDENTITY (1, 1) NOT NULL ,
	[AcctNbr] [bigint] NOT NULL ,
	[RtxnTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RtxnTypCatCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TranAmt] [money] NOT NULL ,
	[ActDateTime] [datetime] NOT NULL ,
	[Description] [char] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_AlertTransaction] PRIMARY KEY  CLUSTERED 
	(
		[AlertTransactionId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AcctNbr] ON [ihb].[AlertTransaction]([AcctNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RtxnTypCatCd] ON [ihb].[AlertTransaction]([RtxnTypCatCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RtxnTypCd] ON [ihb].[AlertTransaction]([RtxnTypCd]) ON [PRIMARY]
GO