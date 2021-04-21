use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchTemplate]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ops].[BatchTemplate]
GO
CREATE TABLE [ops].[BatchTemplate] (
	[BatchTemplateId] [int] NOT NULL ,
	[BatchTemplate] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[QueTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DateLastMaint] [datetime] NOT NULL ,
	CONSTRAINT [PK_BatchTemplate] PRIMARY KEY  CLUSTERED 
	(
		[BatchTemplateId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BatchTemplate] ON [ops].[BatchTemplate]([BatchTemplate]) ON [PRIMARY]
GO