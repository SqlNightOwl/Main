use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCardHolder]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[CompromiseCardHolder]
GO
CREATE TABLE [risk].[CompromiseCardHolder] (
	[CardId] [int] NOT NULL ,
	[AgreeId] [int] NOT NULL ,
	[HolderId] [smallint] NOT NULL ,
	[IssueId] [smallint] NOT NULL ,
	[IncidentId] [int] NOT NULL ,
	[CardHolderNbr] [int] NOT NULL ,
	[CardHolder] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StatusCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CurrentStatusCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[StatusReason] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EffDateTime] [datetime] NULL ,
	[IssuedOn] [datetime] NULL ,
	[ExpiresOn] [datetime] NULL ,
	[Address1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ZipCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Phone] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Mobile] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_CompromiseCardHolder] PRIMARY KEY  CLUSTERED 
	(
		[CardId],
		[HolderId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CardAgreement] ON [risk].[CompromiseCardHolder]([AgreeId], [HolderId], [IssueId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EffDateTime] ON [risk].[CompromiseCardHolder]([EffDateTime]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[CompromiseCardHolder].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[CompromiseCardHolder].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCardHolder].[IncidentId]'
GO
setuser
GO