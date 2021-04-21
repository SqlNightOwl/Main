use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[AlertDetail]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[AlertDetail]
GO
CREATE TABLE [ihb].[AlertDetail] (
	[RequestType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[RTNumber] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ProductType] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_AlertDetail] PRIMARY KEY  CLUSTERED 
	(
		[RequestType],
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RequestedAccount] ON [ihb].[AlertDetail]([RequestType], [AccountNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [ihb].[AlertDetail]([AccountNumber]) ON [PRIMARY]
GO