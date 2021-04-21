use DataSoup
go
ALTER TABLE [risk].[CompromiseCard] ADD CONSTRAINT [CompromiseCard_has_CompromiseAlert] FOREIGN KEY 
	(
		[AlertId]
	) REFERENCES [risk].[CompromiseAlert] (
		[AlertId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO