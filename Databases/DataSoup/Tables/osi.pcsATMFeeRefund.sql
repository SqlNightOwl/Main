use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[pcsATMFeeRefund]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[pcsATMFeeRefund]
GO
CREATE TABLE [osi].[pcsATMFeeRefund] (
	[AccountNumber] [bigint] NOT NULL ,
	[TransactionNumber] [int] NOT NULL ,
	[PostOn] [datetime] NOT NULL ,
	[FeeCharged] [smallmoney] NOT NULL ,
	[FeeRefunded] [smallmoney] NOT NULL ,
	CONSTRAINT [PK_pcsATMFeeRefund] PRIMARY KEY  NONCLUSTERED 
	(
		[AccountNumber],
		[TransactionNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_pcsATMFeeRefund] ON [osi].[pcsATMFeeRefund]([PostOn]) ON [PRIMARY]
GO