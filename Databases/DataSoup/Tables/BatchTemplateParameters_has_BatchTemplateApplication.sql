use DataSoup
go
ALTER TABLE [ops].[BatchTemplateParameters] ADD CONSTRAINT [BatchTemplateParameters_has_BatchTemplateApplication] FOREIGN KEY 
	(
		[BatchTemplateId],
		[ApplNbr],
		[QueSubNbr]
	) REFERENCES [ops].[BatchTemplateApplication] (
		[BatchTemplateId],
		[ApplNbr],
		[QueSubNbr]
	) NOT FOR REPLICATION 
GO
alter table [ops].[BatchTemplateParameters] nocheck constraint [BatchTemplateParameters_has_BatchTemplateApplication]
GO
GO