use DataSoup
go
ALTER TABLE [tcu].[ProcessNotification] ADD CONSTRAINT [ProcessNotification_has_Process] FOREIGN KEY 
	(
		[ProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO