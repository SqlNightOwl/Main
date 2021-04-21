use DataSoup
go
ALTER TABLE [risk].[DeviceIP] ADD CONSTRAINT [DeviceIP_has_Device] FOREIGN KEY 
	(
		[DeviceId]
	) REFERENCES [risk].[Device] (
		[DeviceId]
	) ON DELETE CASCADE  ON UPDATE CASCADE 
GO