use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventRegistration]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[EventRegistration]
GO
CREATE TABLE [mkt].[EventRegistration] (
	[EventRegistrationId] [int] IDENTITY (1, 1) NOT NULL ,
	[EventId] [int] NOT NULL ,
	[EMail] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[First_Name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Last_Name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Company] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Address] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[City] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[State] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Zip_Code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Home_Phone] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Cell_Phone] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Work_Phone] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Is_A_Member] [bit] NOT NULL ,
	[Number_Of_People] [tinyint] NOT NULL ,
	[Comments] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CancelledOn] [datetime] NULL ,
	[Has_Opted_In] [bit] NOT NULL ,
	[User1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[User5] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_EventRegistration] PRIMARY KEY  CLUSTERED 
	(
		[EventRegistrationId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_EventEmail] ON [mkt].[EventRegistration]([EventId], [EMail]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[EventRegistration].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[EventRegistration].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[EventRegistration].[Has_Opted_In]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[EventRegistration].[Is_A_Member]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[EventRegistration].[Number_Of_People]'
GO
setuser
GO
GRANT  SELECT  ON [mkt].[EventRegistration]  TO [wa_Marketing]
GO