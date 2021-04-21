use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[Event]
GO
CREATE TABLE [mkt].[Event] (
	[EventId] [int] IDENTITY (1, 1) NOT NULL ,
	[Event] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EventOn] [datetime] NOT NULL ,
	[RegistrationStartsOn] [datetime] NOT NULL ,
	[RegistrationEndsOn] [datetime] NULL ,
	[IsRecurring] [bit] NOT NULL ,
	[HasUniqueRegistrations] [bit] NOT NULL ,
	[HasAutoResponse] [bit] NOT NULL ,
	[IsInternal] [bit] NOT NULL ,
	[IsEnabled] [bit] NOT NULL ,
	[TicketsAvailable] [smallint] NOT NULL ,
	[TicketsRequested] [smallint] NOT NULL ,
	[TicketsAllowed] [tinyint] NOT NULL ,
	[EventType] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Organizer] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Description] [varchar] (3000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Coordinator] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CoordinatorEmail] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[BCCToCoordinator] [bit] NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Event] PRIMARY KEY  CLUSTERED 
	(
		[EventId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_Event_RegistrationDates] CHECK (case when [IsRecurring]=(1) AND [RegistrationEndsOn] IS NULL then (1) when [IsRecurring]=(0) AND [RegistrationEndsOn] IS NULL then (0) when [RegistrationEndsOn]>=[RegistrationStartsOn] then (1) else (0) end=(1)),
	CONSTRAINT [CK_Event_Tickets] CHECK (case when [TicketsAvailable]=(0) AND [TicketsRequested]=(0) then (1) when [TicketsAvailable]<(0) OR [TicketsRequested]<(0) then (0) when [TicketsRequested]<=[TicketsAvailable] then (1) else (0) end=(1))
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_Event] ON [mkt].[Event]([Event]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[BCCToCoordinator]'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Event].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Event].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[HasAutoResponse]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[HasUniqueRegistrations]'
GO
EXEC sp_bindefault N'[dbo].[df_One]', N'[Event].[IsEnabled]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[IsInternal]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[IsRecurring]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[TicketsAllowed]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[TicketsAvailable]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Event].[TicketsRequested]'
GO
setuser
GO