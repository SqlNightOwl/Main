use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowPayoff]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[EscrowPayoff]
GO
CREATE TABLE [osi].[EscrowPayoff] (
	[Record] [varchar] (132) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Page] [int] NOT NULL ,
	[Row] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_EscrowPayoff] PRIMARY KEY  CLUSTERED 
	(
		[Row]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[EscrowPayoff].[Page]'
GO
setuser
GO