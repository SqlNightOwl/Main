use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Holiday]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Holiday]
GO
CREATE TABLE [tcu].[Holiday] (
	[Holiday] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MonthOccurs] [tinyint] NOT NULL ,
	[Frequency] [tinyint] NOT NULL ,
	[DayOccurs] [tinyint] NOT NULL ,
	[IsFloating] [bit] NOT NULL ,
	[IsFederal] [bit] NOT NULL ,
	[IsCompany] [bit] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Holiday] PRIMARY KEY  NONCLUSTERED 
	(
		[Holiday]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [AK_Holiday] UNIQUE  CLUSTERED 
	(
		[MonthOccurs],
		[Frequency]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_Holiday] CHECK ([DayOccurs]>(0) AND [DayOccurs]<(32)),
	CONSTRAINT [CK_Holiday_Frequency] CHECK ([Frequency]>=(0) AND [Frequency]<(6)),
	CONSTRAINT [CK_Holiday_MonthOccurs] CHECK ([MonthOccurs]>(0) AND [MonthOccurs]<(13))
) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Holiday].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Holiday].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Holiday].[IsCompany]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Holiday].[IsFederal]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Holiday].[IsFloating]'
GO
setuser
GO