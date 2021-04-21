use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetailTCC]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[IrsDetailTCC]
GO
CREATE TABLE [osi].[IrsDetailTCC] (
	[AccountNumber] [bigint] NOT NULL ,
	CONSTRAINT [PK_IrsDetailTCC] PRIMARY KEY  CLUSTERED 
	(
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO