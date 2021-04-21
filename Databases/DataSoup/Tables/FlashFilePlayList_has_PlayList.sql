use DataSoup
go
ALTER TABLE [mkt].[FlashFilePlayList] ADD CONSTRAINT [FlashFilePlayList_has_PlayList] FOREIGN KEY 
	(
		[PlayListId]
	) REFERENCES [mkt].[PlayList] (
		[PlayListId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO