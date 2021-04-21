use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_CompromiseCards')
	EXEC sp_addrole N'wa_CompromiseCards'
GO