use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[Alert]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[Alert]
GO
CREATE TABLE [ihb].[Alert] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[Record] [varchar] (63) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RecordType] [tinyint] NOT NULL ,
	[AlertType] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[Balance] [money] NULL ,
	CONSTRAINT [PK_Alert] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RecordType] ON [ihb].[Alert]([RecordType]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AlterType] ON [ihb].[Alert]([AlertType]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [ihb].[Alert]([AccountNumber]) ON [PRIMARY]
GO
setuser N'ihb'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Alert].[AccountNumber]'
GO
EXEC sp_bindefault N'[dbo].[df_ZeroLengthString]', N'[Alert].[AlertType]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Alert].[RecordType]'
GO
setuser
GO
GRANT  REFERENCES ,  SELECT  ON [ihb].[Alert]  TO [wa_SelfServiceTechnology]
GO