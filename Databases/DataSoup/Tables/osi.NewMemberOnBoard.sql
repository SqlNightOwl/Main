use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[NewMemberOnBoard]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[NewMemberOnBoard]
GO
CREATE TABLE [osi].[NewMemberOnBoard] (
	[AcctNbr] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[BranchNumber] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Name1] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Address1] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CityName] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StateCd] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ZipCd] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Phone] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EmailAddress] [char] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[EmployeeFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ForeignFlag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AccountStatus] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ContractDate] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CloseDate] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[DoNotMail] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CurrMiAcctTypCd] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[AcctLength] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[RowId] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_ClarkAmerican] PRIMARY KEY  CLUSTERED 
	(
		[RowId]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO