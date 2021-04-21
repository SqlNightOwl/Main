use DataSoup
go
ALTER TABLE [risk].[ScanDetail] ADD CONSTRAINT [ScanDetail_has_Scan] FOREIGN KEY 
	(
		[ScanId]
	) REFERENCES [risk].[Scan] (
		[ScanId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO