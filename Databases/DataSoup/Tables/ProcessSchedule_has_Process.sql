use DataSoup
go
ALTER TABLE [tcu].[ProcessSchedule] ADD CONSTRAINT [ProcessSchedule_has_Process] FOREIGN KEY 
	(
		[ProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO