use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire_load]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sst].[BankServWire_load]
GO
CREATE TABLE [sst].[BankServWire_load] (
	[Record] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RecordType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO