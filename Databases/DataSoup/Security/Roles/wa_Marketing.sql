use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_Marketing')
	EXEC sp_addrole N'wa_Marketing'
GO