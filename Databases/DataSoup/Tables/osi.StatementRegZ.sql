use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementRegZ]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[StatementRegZ]
GO
CREATE TABLE [osi].[StatementRegZ] (
	[MemberNumber] [bigint] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[MajorType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MinorType] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DailyRate] [decimal](6, 6) NOT NULL ,
	[AccruedInterest] [money] NOT NULL ,
	[CourtesyPeriod] [tinyint] NOT NULL ,
	CONSTRAINT [PK_StatementCardAct] PRIMARY KEY  CLUSTERED 
	(
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNumber] ON [osi].[StatementRegZ]([MemberNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccountType] ON [osi].[StatementRegZ]([MajorType], [MinorType]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_DailyRate] ON [osi].[StatementRegZ]([DailyRate]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_AccruedInterest] ON [osi].[StatementRegZ]([AccruedInterest]) ON [PRIMARY]
GO