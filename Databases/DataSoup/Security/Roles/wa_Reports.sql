use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_Reports')
	EXEC sp_addrole N'wa_Reports'
GO