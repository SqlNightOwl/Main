use DataSoup
go
ALTER TABLE [ops].[BatchProcessLog] ADD CONSTRAINT [BatchProcessLog_has_BatchTemplateApplication] FOREIGN KEY 
	(
		[BatchTemplateId],
		[ApplExecTime],
		[QueSubNbr]
	) REFERENCES [ops].[BatchTemplateApplication] (
		[BatchTemplateId],
		[ApplNbr],
		[QueSubNbr]
	) NOT FOR REPLICATION 
GO
alter table [ops].[BatchProcessLog] nocheck constraint [BatchProcessLog_has_BatchTemplateApplication]
GO
GO