use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Survey]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[Survey]
GO
CREATE TABLE [mkt].[Survey] (
	[SurveyId] [int] IDENTITY (1, 1) NOT NULL ,
	[URL] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LoadedOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_Survey] PRIMARY KEY  CLUSTERED 
	(
		[SurveyId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Survey].[LoadedOn]'
GO
setuser
GO