use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventResponse]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[EventResponse]
GO
CREATE TABLE [mkt].[EventResponse] (
	[EventId] [int] NOT NULL ,
	[MessageType] [tinyint] NOT NULL ,
	[Subject] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Body] [varchar] (-1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_EventResponse] PRIMARY KEY  CLUSTERED 
	(
		[EventId],
		[MessageType]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[EventResponse].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[EventResponse].[CreatedOn]'
GO
setuser
GO