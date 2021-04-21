use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[LocationHour]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[LocationHour]
GO
CREATE TABLE [tcu].[LocationHour] (
	[LocationHourId] [int] IDENTITY (1, 1) NOT NULL ,
	[LocationId] [int] NOT NULL ,
	[DaysOfWeek] [smallint] NOT NULL ,
	[FromHour] [datetime] NOT NULL ,
	[ToHour] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_LocationHour] PRIMARY KEY  CLUSTERED 
	(
		[LocationHourId]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_LocationHour_HoursOfOperation] CHECK (case when CONVERT([float],[FromHour],0)>(1) OR CONVERT([float],[ToHour],0)>(1) then (0) when CONVERT([float],[FromHour],0)<(0) OR CONVERT([float],[ToHour],0)<(0) then (0) when CONVERT([float],[FromHour],0)=(0) OR CONVERT([float],[ToHour],0)=(0) then (1) when CONVERT([float],[FromHour],0)<=CONVERT([float],[ToHour],0) then (1) else (0) end=(1))
) ON [PRIMARY]
GO
 CREATE  INDEX [Location_FK] ON [tcu].[LocationHour]([LocationId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[LocationHour].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[LocationHour].[CreatedOn]'
GO
setuser
GO