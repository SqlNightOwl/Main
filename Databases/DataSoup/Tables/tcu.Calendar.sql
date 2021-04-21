use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Calendar]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Calendar]
GO
CREATE TABLE [tcu].[Calendar] (
	[HolidayOn] [datetime] NOT NULL ,
	[Holiday] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[IsCompany] [bit] NOT NULL ,
	[IsFederal] [bit] NOT NULL ,
	CONSTRAINT [PK_Calendar] PRIMARY KEY  CLUSTERED 
	(
		[HolidayOn]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsCompanyHoliday] ON [tcu].[Calendar]([IsCompany]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_IsFederalHoliday] ON [tcu].[Calendar]([IsFederal]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Calendar].[IsCompany]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[Calendar].[IsFederal]'
GO
setuser
GO