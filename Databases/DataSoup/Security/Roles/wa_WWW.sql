use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_WWW')
	EXEC sp_addrole N'wa_WWW'
GO