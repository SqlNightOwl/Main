use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncrRemoteCaptureRaw]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ncrRemoteCaptureRaw]
GO
CREATE TABLE [osi].[ncrRemoteCaptureRaw] (
	[RowType] [tinyint] NOT NULL ,
	[Col1] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Col2] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Col3] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Col4] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Col5] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Col6] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_ncrRemoteCaptureRaw] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO