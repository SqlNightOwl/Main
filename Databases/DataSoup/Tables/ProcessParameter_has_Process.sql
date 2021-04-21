use DataSoup
go
ALTER TABLE [tcu].[ProcessParameter] ADD CONSTRAINT [ProcessParameter_has_Process] FOREIGN KEY 
	(
		[ProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO