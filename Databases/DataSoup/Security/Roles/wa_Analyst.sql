use DataSoup
go
if not exists (select * from dbo.sysusers where name = N'wa_Analyst')
	EXEC sp_addrole N'wa_Analyst'
GO