use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[MemberFee]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[MemberFee]
GO
CREATE TABLE [ihb].[MemberFee] (
	[MemberNumber] [bigint] NOT NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_MemberNumber] ON [ihb].[MemberFee]([MemberNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO