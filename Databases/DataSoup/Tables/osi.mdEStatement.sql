use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdEStatement]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[mdEStatement]
GO
CREATE TABLE [osi].[mdEStatement] (
	[MemberNumber] [bigint] NOT NULL ,
	CONSTRAINT [PK_mdEStatement] PRIMARY KEY  CLUSTERED 
	(
		[MemberNumber]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO