use DataSoup
go
ALTER TABLE [tcu].[ProcessChain] ADD CONSTRAINT [ScheduledProcess_is_Process] FOREIGN KEY 
	(
		[ScheduledProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO