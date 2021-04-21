use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_SharePoint')
	EXEC sp_addrole N'wa_SharePoint'
GO