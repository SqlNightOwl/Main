use DataSoup
go
ALTER TABLE [mkt].[EventField] ADD CONSTRAINT [EventField_has_EventFieldDetail] FOREIGN KEY 
	(
		[Field]
	) REFERENCES [mkt].[EventFieldDetail] (
		[Field]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO