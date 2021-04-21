use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_Date]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[dim_Date]
GO
CREATE TABLE [wh].[dim_Date] (
	[DateId] [int] NOT NULL ,
	[DateValue] [datetime] NOT NULL ,
	[MonthNumber] [tinyint] NOT NULL ,
	[DayNumber] [tinyint] NOT NULL ,
	[DayOfWeek] [tinyint] NOT NULL ,
	[DayOfYear] [smallint] NOT NULL ,
	[YearNumber] [smallint] NOT NULL ,
	[QuarterNumber] [tinyint] NOT NULL ,
	[WeekOfYear] [tinyint] NOT NULL ,
	[IsFederalHoliday] [bit] NOT NULL ,
	[IsCompanyHoliday] [bit] NOT NULL ,
	[DayOfWeekNameShort] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[WeekPart] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_dim_Date_WeekPart] DEFAULT ('Weekday'),
	[QuarterName] [char] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DateNameShort] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DateNameLong] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DayOfWeekName] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MonthName] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[HolidayName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_dim_Date_HolidayName] DEFAULT ('not a holiday'),
	CONSTRAINT [PK_dim_Date] PRIMARY KEY  CLUSTERED 
	(
		[DateId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  UNIQUE  INDEX [AK_dim_Date] ON [wh].[dim_Date]([DateValue]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MonthNumber] ON [wh].[dim_Date]([MonthNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DayNumber] ON [wh].[dim_Date]([DayNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DayOfWeek] ON [wh].[dim_Date]([DayOfWeek]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DayOfYear] ON [wh].[dim_Date]([DayOfYear]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_YearNumber] ON [wh].[dim_Date]([YearNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QuarterNumber] ON [wh].[dim_Date]([QuarterNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_WeekOfYear] ON [wh].[dim_Date]([WeekOfYear]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsFederalHoliday] ON [wh].[dim_Date]([IsFederalHoliday]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsCompanyHoliday] ON [wh].[dim_Date]([IsCompanyHoliday]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DayOfWeekNameShort] ON [wh].[dim_Date]([DayOfWeekNameShort]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_WeekPart] ON [wh].[dim_Date]([WeekPart]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_QuarterName] ON [wh].[dim_Date]([QuarterName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DateNameShort] ON [wh].[dim_Date]([DateNameShort]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DateNameLong] ON [wh].[dim_Date]([DateNameLong]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DayOfWeekName] ON [wh].[dim_Date]([DayOfWeekName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MonthName] ON [wh].[dim_Date]([MonthName]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_HolidayName] ON [wh].[dim_Date]([HolidayName]) ON [PRIMARY]
GO