use DataSoup
go
ALTER TABLE [osi].[IrsDetail] ADD CONSTRAINT [IrsDetail_has_IrsReport] FOREIGN KEY 
	(
		[IrsReportId]
	) REFERENCES [osi].[IrsReport] (
		[IrsReportId]
	)
GO