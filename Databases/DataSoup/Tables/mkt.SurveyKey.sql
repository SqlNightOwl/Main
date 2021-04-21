use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[SurveyKey]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[SurveyKey]
GO
CREATE TABLE [mkt].[SurveyKey] (
	[SurveyKeyId] [int] NOT NULL ,
	[SurveyKey] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SurveyId] [int] NOT NULL ,
	CONSTRAINT [PK_SurveyKey] PRIMARY KEY  CLUSTERED 
	(
		[SurveyKeyId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Survey] ON [mkt].[SurveyKey]([SurveyId]) ON [PRIMARY]
GO