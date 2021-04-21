use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ftiALMExtract]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ftiALMExtract]
GO
CREATE TABLE [osi].[ftiALMExtract] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[FileType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FTIALMExtract_FileType] DEFAULT ('DIL'),
	[Account] [bigint] NOT NULL CONSTRAINT [DF_FTIALMExtract_Account] DEFAULT ((0)),
	[StatusCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FTIALMExtract_StatusCd] DEFAULT ('X'),
	[Record] [varchar] (276) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_FTIALMExtract] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_FileType] ON [osi].[ftiALMExtract]([FileType]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Account] ON [osi].[ftiALMExtract]([Account]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_StatusCd] ON [osi].[ftiALMExtract]([StatusCd]) ON [PRIMARY]
GO