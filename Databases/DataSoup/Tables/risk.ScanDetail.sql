use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ScanDetail]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[ScanDetail]
GO
CREATE TABLE [risk].[ScanDetail] (
	[ScanId] [smallint] NOT NULL CONSTRAINT [DF_ScanDetail_ScanId] DEFAULT ((9)),
	[ScanDetailId] [smallint] IDENTITY (1, 1) NOT NULL ,
	[DeviceId] [int] NOT NULL CONSTRAINT [DF_ScanDetail_DeviceId] DEFAULT ((0)),
	[IP] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RawProtocol] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ScriptId] [int] NOT NULL ,
	[Severity] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Detail] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[PortName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Port] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Protocol] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AssignedTo] [int] NOT NULL ,
	[Status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ScanDetail_Status] DEFAULT ('Open'),
	[Resolution] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ApprovedBy] [int] NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ScanDetail] PRIMARY KEY  CLUSTERED 
	(
		[ScanId],
		[ScanDetailId]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_ScanDetail_AcceptedRisk] CHECK (case [Status] when 'Accept' then len(isnull(rtrim([ApprovedBy]),''))*len(isnull(rtrim([Resolution]),'')) else (1) end>(0)),
	CONSTRAINT [CK_ScanDetail_Severity] CHECK ([Severity]='High' OR [Severity]='Medium' OR [Severity]='Low' OR [Severity]='Unk' OR [Severity]='Info'),
	CONSTRAINT [CK_ScanDetail_Status] CHECK ([Status]='Fixed' OR [Status]='Accept' OR [Status]='Research' OR [Status]='Open')
) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Scan] ON [risk].[ScanDetail]([ScanId]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Device_Script_Protocol] ON [risk].[ScanDetail]([DeviceId], [ScriptId], [RawProtocol]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IP] ON [risk].[ScanDetail]([IP]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Status] ON [risk].[ScanDetail]([Status]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AssignedTo] ON [risk].[ScanDetail]([AssignedTo]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_Device] ON [risk].[ScanDetail]([DeviceId]) ON [PRIMARY]
GO
setuser N'risk'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[ScanDetail].[AssignedTo]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ScanDetail].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ScanDetail].[CreatedOn]'
GO
setuser
GO