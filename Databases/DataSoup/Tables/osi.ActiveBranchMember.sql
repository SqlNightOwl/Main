use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranchMember]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ActiveBranchMember]
GO
CREATE TABLE [osi].[ActiveBranchMember] (
	[MemberNumber] [bigint] NOT NULL ,
	[BranchCd] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[StepId] [tinyint] NOT NULL ,
	CONSTRAINT [PK_ActiveBranchMember] PRIMARY KEY  CLUSTERED 
	(
		[MemberNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_BranchCd] ON [osi].[ActiveBranchMember]([BranchCd]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_StepId] ON [osi].[ActiveBranchMember]([StepId]) ON [PRIMARY]
GO