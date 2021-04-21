use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[BankServWire]
GO
CREATE TABLE [sst].[BankServWire] (
	[WireId] [smallint] NOT NULL ,
	[Status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FileDate] [int] NULL ,
	[Amount] [money] NULL ,
	[SenderAccount] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ReceiverName] [varchar] (23) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ReceiverBank] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ReceiverAccount] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WireFile] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[WireLoadedOn] [datetime] NULL ,
	[IMAD] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AcknowledgmentFile] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AcknowledgedOn] [datetime] NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [PK_BankServWire] ON [sst].[BankServWire]([WireId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileDate] ON [sst].[BankServWire]([FileDate]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [IX_WireLoadedOn] ON [sst].[BankServWire]([WireLoadedOn]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO