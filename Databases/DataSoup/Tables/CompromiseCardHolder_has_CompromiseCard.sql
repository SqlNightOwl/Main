use DataSoup
go
ALTER TABLE [risk].[CompromiseCardHolder] ADD CONSTRAINT [CompromiseCardHolder_has_CompromiseCard] FOREIGN KEY 
	(
		[CardId]
	) REFERENCES [risk].[CompromiseCard] (
		[CardId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO