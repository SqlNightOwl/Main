use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_SecurityScan')
	EXEC sp_addrole N'wa_SecurityScan'
GO