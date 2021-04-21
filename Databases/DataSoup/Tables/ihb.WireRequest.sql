use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[WireRequest]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[WireRequest]
GO
CREATE TABLE [ihb].[WireRequest] (
	[WireRequestId] [int] NOT NULL ,
	[RequestedOn] [datetime] NOT NULL ,
	[MemberNumber] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MemberName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Amount] [money] NULL ,
	[WireTo] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Request] [varchar] (-1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_WireRequest] PRIMARY KEY  CLUSTERED 
	(
		[WireRequestId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_RequestedOn] ON [ihb].[WireRequest]([RequestedOn]) ON [PRIMARY]
GO