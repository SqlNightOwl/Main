use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Statement]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[Statement]
GO
CREATE TABLE [osi].[Statement] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[QueueId] [int] NOT NULL CONSTRAINT [DF_Statement_QueueId] DEFAULT ((84789)),
	[Type] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Statement_Type] DEFAULT ('EOM'),
	[Record] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Account] [bigint] NOT NULL ,
	[Member] [bigint] NOT NULL ,
	CONSTRAINT [PK_Statement] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QueueId] ON [osi].[Statement]([QueueId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_TypeQueueIdRecordId] ON [osi].[Statement]([Type], [QueueId], [RecordId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Type] ON [osi].[Statement]([Type]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Account] ON [osi].[Statement]([Account]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Member] ON [osi].[Statement]([Member]) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Statement].[Account]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Statement].[Member]'
GO
setuser
GO