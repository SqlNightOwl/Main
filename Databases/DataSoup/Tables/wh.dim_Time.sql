use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_Time]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_Time]
GO
CREATE TABLE [wh].[dim_Time] (
	[TimeId] [smallint] NOT NULL ,
	[TimeValue] [datetime] NOT NULL ,
	[HourOfDay] [tinyint] NOT NULL ,
	[MinuteOfHour] [tinyint] NOT NULL ,
	[QuarterHour] [tinyint] NOT NULL ,
	[Meridiem] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Time24Hour] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Time12Hour] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DaySegment] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	CONSTRAINT [PK_dim_Time] PRIMARY KEY  CLUSTERED 
	(
		[TimeId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_Time] ON [wh].[dim_Time]([TimeValue]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_HourOfDay] ON [wh].[dim_Time]([HourOfDay]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MinuteOfHour] ON [wh].[dim_Time]([MinuteOfHour]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QuarterHour] ON [wh].[dim_Time]([QuarterHour]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Meridiem] ON [wh].[dim_Time]([Meridiem]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DaySegment] ON [wh].[dim_Time]([DaySegment]) ON [PRIMARY]
GO