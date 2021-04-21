use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_HelpDesk')
	EXEC sp_addrole N'wa_HelpDesk'
GO