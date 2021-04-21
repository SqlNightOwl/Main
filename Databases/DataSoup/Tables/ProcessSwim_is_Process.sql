use DataSoup
go
ALTER TABLE [tcu].[ProcessSwim] ADD CONSTRAINT [ProcessSwim_is_Process] FOREIGN KEY 
	(
		[ProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO