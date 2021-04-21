use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_SelfServiceTechnology')
	EXEC sp_addrole N'wa_SelfServiceTechnology'
GO