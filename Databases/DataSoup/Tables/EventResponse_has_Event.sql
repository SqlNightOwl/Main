use DataSoup
go
ALTER TABLE [mkt].[EventResponse] ADD CONSTRAINT [EventResponse_has_Event] FOREIGN KEY 
	(
		[EventId]
	) REFERENCES [mkt].[Event] (
		[EventId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO