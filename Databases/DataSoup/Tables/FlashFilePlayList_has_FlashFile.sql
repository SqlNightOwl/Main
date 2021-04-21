use DataSoup
go
ALTER TABLE [mkt].[FlashFilePlayList] ADD CONSTRAINT [FlashFilePlayList_has_FlashFile] FOREIGN KEY 
	(
		[FlashFileId]
	) REFERENCES [mkt].[FlashFile] (
		[FlashFileId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO