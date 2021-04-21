use DataSoup
go
ALTER TABLE [mkt].[EventRegistration] ADD CONSTRAINT [EventRegistration_has_Event] FOREIGN KEY 
	(
		[EventId]
	) REFERENCES [mkt].[Event] (
		[EventId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO