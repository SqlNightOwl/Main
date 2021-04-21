use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_Services')
	EXEC sp_addrole N'wa_Services'
GO