use DataSoup
go
ALTER TABLE [tcu].[Location] ADD CONSTRAINT [Location_has_PlayList] FOREIGN KEY 
	(
		[PlayListId]
	) REFERENCES [mkt].[PlayList] (
		[PlayListId]
	)
GO