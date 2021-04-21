use DataSoup
go
create rule [dbo].[ck_ValueType] as (@ValueType = 'datetime' or (@ValueType = 'boolean' or (@ValueType = 'number' or @ValueType = 'string' or @ValueType = 'list')));
GO