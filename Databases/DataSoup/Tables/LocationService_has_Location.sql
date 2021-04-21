use DataSoup
go
ALTER TABLE [tcu].[LocationService] ADD CONSTRAINT [LocationService_has_Location] FOREIGN KEY 
	(
		[LocationId]
	) REFERENCES [tcu].[Location] (
		[LocationId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO