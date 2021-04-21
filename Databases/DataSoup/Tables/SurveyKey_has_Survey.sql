use DataSoup
go
ALTER TABLE [mkt].[SurveyKey] ADD CONSTRAINT [SurveyKey_has_Survey] FOREIGN KEY 
	(
		[SurveyId]
	) REFERENCES [mkt].[Survey] (
		[SurveyId]
	) ON DELETE CASCADE 
GO