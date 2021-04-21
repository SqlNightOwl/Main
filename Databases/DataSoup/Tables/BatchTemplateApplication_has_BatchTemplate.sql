use DataSoup
go
ALTER TABLE [ops].[BatchTemplateApplication] ADD CONSTRAINT [BatchTemplateApplication_has_BatchTemplate] FOREIGN KEY 
	(
		[BatchTemplateId]
	) REFERENCES [ops].[BatchTemplate] (
		[BatchTemplateId]
	) NOT FOR REPLICATION 
GO
alter table [ops].[BatchTemplateApplication] nocheck constraint [BatchTemplateApplication_has_BatchTemplate]
GO
GO