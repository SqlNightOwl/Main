use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_Lending')
	EXEC sp_addrole N'wa_Lending'
GO