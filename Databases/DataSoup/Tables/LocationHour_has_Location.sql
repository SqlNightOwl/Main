use DataSoup
go
ALTER TABLE [tcu].[LocationHour] ADD CONSTRAINT [LocationHour_has_Location] FOREIGN KEY 
	(
		[LocationId]
	) REFERENCES [tcu].[Location] (
		[LocationId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO