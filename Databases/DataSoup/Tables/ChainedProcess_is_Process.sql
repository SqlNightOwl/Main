use DataSoup
go
ALTER TABLE [tcu].[ProcessChain] ADD CONSTRAINT [ChainedProcess_is_Process] FOREIGN KEY 
	(
		[ChainedProcessId]
	) REFERENCES [tcu].[Process] (
		[ProcessId]
	)
GO