use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncpCoupon]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ncpCoupon]
GO
CREATE TABLE [osi].[ncpCoupon] (
	[RecordId] [int] IDENTITY (1, 1) NOT NULL ,
	[Record] [char] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	CONSTRAINT [PK_ncpCoupon] PRIMARY KEY  CLUSTERED 
	(
		[RecordId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountNumber] ON [osi].[ncpCoupon]([AccountNumber]) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ncpCoupon].[AccountNumber]'
GO
setuser
GO