use DataSoup
go
ALTER TABLE [risk].[ScanDetail] ADD CONSTRAINT [ScanDetail_has_Device] FOREIGN KEY 
	(
		[DeviceId]
	) REFERENCES [risk].[Device] (
		[DeviceId]
	) ON DELETE CASCADE  NOT FOR REPLICATION 
GO
alter table [risk].[ScanDetail] nocheck constraint [ScanDetail_has_Device]
GO
GO