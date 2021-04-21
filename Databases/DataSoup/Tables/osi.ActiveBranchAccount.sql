use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranchAccount]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ActiveBranchAccount]
GO
CREATE TABLE [osi].[ActiveBranchAccount] (
	[MemberNumber] [bigint] NOT NULL ,
	[AccountNumber] [bigint] NOT NULL ,
	[BranchCd] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[OpenedOn] [datetime] NULL ,
	CONSTRAINT [PK_ActiveBranchAccount] PRIMARY KEY  CLUSTERED 
	(
		[AccountNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BranchCd] ON [osi].[ActiveBranchAccount]([BranchCd]) ON [PRIMARY]
GO
 CREATE  INDEX [FK_ActiveBranchMember] ON [osi].[ActiveBranchAccount]([MemberNumber]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_OpenedOn] ON [osi].[ActiveBranchAccount]([OpenedOn]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNumber] ON [osi].[ActiveBranchAccount]([MemberNumber]) ON [PRIMARY]
GO