use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Survey_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[Survey_load]
GO
CREATE TABLE [mkt].[Survey_load] (
	[SurveyKeyId] [int] NOT NULL ,
	[URL] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SurveyKey] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL 
) ON [PRIMARY]
GO