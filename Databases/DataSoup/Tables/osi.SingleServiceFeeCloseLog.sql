use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[SingleServiceFeeCloseLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[SingleServiceFeeCloseLog]
GO
CREATE TABLE [osi].[SingleServiceFeeCloseLog] (
	[AccountNumber] [bigint] NOT NULL ,
	[CloseOn] [datetime] NOT NULL ,
	CONSTRAINT [PK_SingleServiceFeeCloseLog] PRIMARY KEY  CLUSTERED 
	(
		[CloseOn],
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'osi'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[SingleServiceFeeCloseLog].[CloseOn]'
GO
setuser
GO