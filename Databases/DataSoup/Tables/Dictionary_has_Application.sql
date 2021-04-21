use DataSoup
go
ALTER TABLE [tcu].[Dictionary] ADD CONSTRAINT [Dictionary_has_Application] FOREIGN KEY 
	(
		[Application]
	) REFERENCES [tcu].[Application] (
		[Application]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO