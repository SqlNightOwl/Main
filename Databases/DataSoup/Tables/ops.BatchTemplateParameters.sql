use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[BatchTemplateParameters]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ops].[BatchTemplateParameters]
GO
CREATE TABLE [ops].[BatchTemplateParameters] (
	[BatchTemplateId] [int] NOT NULL ,
	[ApplNbr] [int] NOT NULL ,
	[QueSubNbr] [smallint] NOT NULL ,
	[ParameterCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ParameterValue] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DateLastMaint] [datetime] NOT NULL ,
	CONSTRAINT [PK_BatchTemplateParameters] PRIMARY KEY  CLUSTERED 
	(
		[BatchTemplateId],
		[ApplNbr],
		[QueSubNbr],
		[ParameterCd]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_BatchTemplate] ON [ops].[BatchTemplateParameters]([BatchTemplateId], [ApplNbr], [QueSubNbr]) ON [PRIMARY]
GO