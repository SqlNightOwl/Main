use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[GiftCard]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[GiftCard]
GO
CREATE TABLE [mkt].[GiftCard] (
	[MemberNumber] [bigint] NOT NULL ,
	[WasSuccessful] [bit] NOT NULL ,
	[CreatedOn] [datetime] NOT NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_MemberNumberCreatedOn] ON [mkt].[GiftCard]([CreatedOn], [MemberNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO