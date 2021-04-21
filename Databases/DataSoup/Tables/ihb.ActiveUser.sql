use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[ActiveUser]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [ihb].[ActiveUser]
GO
CREATE TABLE [ihb].[ActiveUser] (
	[Period] [int] NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[UserId] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[LastSuccessfulLogin] [datetime] NULL ,
	[FirstName] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[LastName] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TaxId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EMail] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[DayPhone] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EvePhone] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[EnrolledOn] [datetime] NULL ,
	[BillPayEnrolledOn] [datetime] NULL ,
	[LastUpdateOn] [datetime] NULL ,
	[BillPayFeeAccountType] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ServiceType] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FromAccountId] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[FromHostAccount1] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PaymentCount] [int] NOT NULL ,
	[PaymentAmount] [money] NOT NULL ,
	[FailedCount] [int] NOT NULL ,
	[FailedAmount] [money] NOT NULL ,
	[MaxProcessOn] [datetime] NULL ,
	[TransferCount] [int] NOT NULL ,
	[TransferAmount] [money] NOT NULL ,
	[NumberOfSignOns] [int] NOT NULL ,
	[LastBillPayOn] [datetime] NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_ActiveUser] ON [ihb].[ActiveUser]([Period], [MemberNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNumber] ON [ihb].[ActiveUser]([MemberNumber]) ON [PRIMARY]
GO