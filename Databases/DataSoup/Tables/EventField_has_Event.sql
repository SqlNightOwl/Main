use DataSoup
go
ALTER TABLE [mkt].[EventField] ADD CONSTRAINT [EventField_has_Event] FOREIGN KEY 
	(
		[EventId]
	) REFERENCES [mkt].[Event] (
		[EventId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO