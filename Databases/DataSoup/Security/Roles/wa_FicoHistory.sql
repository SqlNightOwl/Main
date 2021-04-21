use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_FicoHistory')
	EXEC sp_addrole N'wa_FicoHistory'
GO