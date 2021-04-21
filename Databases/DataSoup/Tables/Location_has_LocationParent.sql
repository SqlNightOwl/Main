use DataSoup
go
ALTER TABLE [tcu].[Location] ADD CONSTRAINT [Location_has_LocationParent] FOREIGN KEY 
	(
		[ParentId]
	) REFERENCES [tcu].[Location] (
		[LocationId]
	)
GO