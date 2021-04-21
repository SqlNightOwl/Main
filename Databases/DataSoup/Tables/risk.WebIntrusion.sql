use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[WebIntrusion]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[WebIntrusion]
GO
CREATE TABLE [risk].[WebIntrusion] (
	[row] [int] IDENTITY (1, 1) NOT NULL ,
	[MemberNumber] [bigint] NOT NULL ,
	[MemberName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[SSN] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[JointName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[JointSSN] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POD1Name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POD1SSN] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POD2Name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POD2SSN] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POD3Name] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[POD3SSN] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_WebIntrusion] PRIMARY KEY  CLUSTERED 
	(
		[row]
	) WITH  FILLFACTOR = 100  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_MemberNumber] ON [risk].[WebIntrusion]([MemberNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO