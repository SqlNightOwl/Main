use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ColonialMember]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[ColonialMember]
GO
CREATE TABLE [osi].[ColonialMember] (
	[ColonialLoanNum] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[TaxId1] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[TaxId2] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Match] [tinyint] NOT NULL ,
	CONSTRAINT [PK_ColonialMember] PRIMARY KEY  CLUSTERED 
	(
		[ColonialLoanNum],
		[MemberNumber]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] 
) ON [PRIMARY]
GO