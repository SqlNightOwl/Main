use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchTemplateApplication]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ops].[BatchTemplateApplication]
GO
CREATE TABLE [ops].[BatchTemplateApplication] (
	[BatchTemplateId] [int] NOT NULL ,
	[ApplNbr] [int] NOT NULL ,
	[QueSubNbr] [smallint] NOT NULL ,
	[SeqNbr] [smallint] NULL ,
	[ApplName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ApplDesc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StdDev] [int] NOT NULL ,
	[Median] [int] NOT NULL ,
	[DateLastMaint] [datetime] NOT NULL ,
	[InactiveOn] [datetime] NULL ,
	CONSTRAINT [PK_BatchTemplateApplication] PRIMARY KEY  CLUSTERED 
	(
		[BatchTemplateId],
		[ApplNbr],
		[QueSubNbr]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_InactiveOn] ON [ops].[BatchTemplateApplication]([InactiveOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DateLastMaint] ON [ops].[BatchTemplateApplication]([DateLastMaint]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_StdDev] ON [ops].[BatchTemplateApplication]([StdDev]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO
 CREATE  INDEX [IX_ApplNbrQueSubNbr] ON [ops].[BatchTemplateApplication]([ApplNbr], [QueSubNbr]) WITH  FILLFACTOR = 80 ON [PRIMARY]
GO