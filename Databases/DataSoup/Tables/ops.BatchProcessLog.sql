use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchProcessLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ops].[BatchProcessLog]
GO
CREATE TABLE [ops].[BatchProcessLog] (
	[BatchProcessLogId] [int] IDENTITY (1, 1) NOT NULL ,
	[BatchTemplateId] [int] NULL ,
	[NtwkNodeName] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ApplNbr] [int] NOT NULL ,
	[QueSubNbr] [smallint] NOT NULL ,
	[SeqNbr] [smallint] NULL ,
	[QueNbr] [int] NOT NULL ,
	[EffDate] [datetime] NULL ,
	[SchedDateTime] [datetime] NOT NULL ,
	[ApplStartTime] [datetime] NULL ,
	[ApplStopTime] [datetime] NULL ,
	[ApplExecTime] [int] NULL ,
	[ReturnCd] [int] NULL ,
	[StdDev] [int] NOT NULL ,
	[Median] [int] NOT NULL ,
	CONSTRAINT [PK_BatchProcessLog] PRIMARY KEY  CLUSTERED 
	(
		[BatchProcessLogId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QueNbr] ON [ops].[BatchProcessLog]([QueNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplStartTime] ON [ops].[BatchProcessLog]([ApplStartTime]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_BatchTemplateApplication] ON [ops].[BatchProcessLog]([BatchTemplateId], [ApplNbr], [QueSubNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_BatchTemplate] ON [ops].[BatchProcessLog]([BatchTemplateId]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO
 CREATE  INDEX [IX_EffDate] ON [ops].[BatchProcessLog]([EffDate]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QueNbrApplNbrQueSubNbr] ON [ops].[BatchProcessLog]([QueNbr], [ApplNbr], [QueSubNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QueSubNbr] ON [ops].[BatchProcessLog]([QueSubNbr]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplNbr] ON [ops].[BatchProcessLog]([ApplNbr]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO