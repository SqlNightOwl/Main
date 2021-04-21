use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[CompromiseCard]
GO
CREATE TABLE [risk].[CompromiseCard] (
	[CardId] [int] IDENTITY (1, 1) NOT NULL ,
	[AlertId] [int] NOT NULL ,
	[CardNumber] [bigint] NOT NULL ,
	[IsInitialReport] [bit] NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[Member] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CompromiseCard_Member] DEFAULT ('Not Found'),
	[MemberGroup] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CompromiseCard_MemberGroup] DEFAULT ('UNK'),
	[Owner] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CompromiseCard_MemberName] DEFAULT ('Not Found'),
	[OwnerType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CompromiseCard_CustomerType] DEFAULT ('UNK'),
	[OwnerId] [int] NOT NULL ,
	[AgreeTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AgreeId] [int] NOT NULL ,
	[PrimaryHolderId] [smallint] NOT NULL ,
	[OSIStatusCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CNSStatus] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CNSStatusOn] [datetime] NULL ,
	[HasFraud] [tinyint] NOT NULL ,
	[FraudReportedOn] [datetime] NULL ,
	[AmountReported] [money] NOT NULL ,
	[AmountRecovered] [money] NOT NULL ,
	[FinalLossOn] [datetime] NULL ,
	[IsReissued] [tinyint] NOT NULL ,
	[ReissueType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CardsReissued] [tinyint] NOT NULL ,
	[CutOffGroup] [tinyint] NOT NULL ,
	[CutOffOn] [datetime] NULL ,
	[LastUsedOn] [datetime] NULL ,
	[Comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[InitialAlertId] [int] NULL ,
	[InitialStatusCode] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_CompromiseCard] PRIMARY KEY  CLUSTERED 
	(
		[CardId]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_CompromiseCard_HasFraud] CHECK ([HasFraud]=(1) OR [HasFraud]=(0)),
	CONSTRAINT [CK_CompromiseCard_IsReissued] CHECK ([IsReissued]=(1) OR [IsReissued]=(0))
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_CompromiseAlert] ON [risk].[CompromiseCard]([AlertId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AlertCard] ON [risk].[CompromiseCard]([AlertId], [CardNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberGroup] ON [risk].[CompromiseCard]([AlertId], [MemberGroup]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNumber] ON [risk].[CompromiseCard]([MemberNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Owner] ON [risk].[CompromiseCard]([OwnerType], [OwnerId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CutOffGroup] ON [risk].[CompromiseCard]([CutOffGroup]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OSIStatusCode] ON [risk].[CompromiseCard]([OSIStatusCode]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AgreeId] ON [risk].[CompromiseCard]([AgreeId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AlertId] ON [risk].[CompromiseCard]([AlertId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsInitialReport] ON [risk].[CompromiseCard]([IsInitialReport]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_CardNumber] ON [risk].[CompromiseCard]([CardNumber]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[AgreeId]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[AmountRecovered]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[AmountReported]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[CardsReissued]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[CompromiseCard].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_Today]', N'[CompromiseCard].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[CutOffGroup]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[HasFraud]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[InitialAlertId]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[CompromiseCard].[IsInitialReport]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[IsReissued]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[MemberNumber]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[OwnerId]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[CompromiseCard].[PrimaryHolderId]'
GO
setuser
GO
GRANT  REFERENCES ,  SELECT ,  UPDATE  ON [risk].[CompromiseCard]  TO [wa_CompromiseCards]
GO