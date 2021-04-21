use DataSoup
go
ALTER TABLE [tcu].[ReferenceValue] ADD CONSTRAINT [ReferenceValue_has_Reference] FOREIGN KEY 
	(
		[ReferenceId]
	) REFERENCES [tcu].[Reference] (
		[ReferenceId]
	) ON DELETE CASCADE 
GO