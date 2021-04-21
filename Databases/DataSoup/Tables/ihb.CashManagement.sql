use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[CashManagement]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[CashManagement]
GO
CREATE TABLE [ihb].[CashManagement] (
	[Record] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	[LineType] [tinyint] NOT NULL ,
	[Sequence] [int] NOT NULL ,
	CONSTRAINT [PK_CashManagement] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_LineType] ON [ihb].[CashManagement]([LineType]) ON [PRIMARY]
GO
setuser N'ihb'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CashManagement].[LineType]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CashManagement].[Sequence]'
GO
setuser
GO
GRANT  REFERENCES ,  SELECT  ON [ihb].[CashManagement]  TO [wa_SelfServiceTechnology]
GO