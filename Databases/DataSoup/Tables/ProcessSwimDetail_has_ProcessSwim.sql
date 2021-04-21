use DataSoup
go
ALTER TABLE [tcu].[ProcessSwimDetail] ADD CONSTRAINT [ProcessSwimDetail_has_ProcessSwim] FOREIGN KEY 
	(
		[ProcessId]
	) REFERENCES [tcu].[ProcessSwim] (
		[ProcessId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO