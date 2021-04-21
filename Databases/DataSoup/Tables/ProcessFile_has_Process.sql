use DataSoup
go
ALTER TABLE [tcu].[ProcessFile] ADD CONSTRAINT [ProcessFile_has_Process] FOREIGN KEY 
	(
		[ProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO