use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_Process')
	EXEC sp_addrole N'wa_Process'
GO