use DataSoup
go
ALTER TABLE [risk].[CompromiseAlert] ADD CONSTRAINT [CompromiseAlert_has_Compromise] FOREIGN KEY 
	(
		[CompromiseId]
	) REFERENCES [risk].[Compromise] (
		[CompromiseId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO