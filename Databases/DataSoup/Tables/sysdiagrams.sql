use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[sysdiagrams]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [sysdiagrams]
GO
CREATE TABLE [sysdiagrams] (
	[name] [sysname] NOT NULL ,
	[principal_id] [int] NOT NULL ,
	[diagram_id] [int] IDENTITY (1, 1) NOT NULL ,
	[version] [int] NULL ,
	[definition] [varbinary] (-1) NULL ,
	 PRIMARY KEY  CLUSTERED 
	(
		[diagram_id]
	)  ON [PRIMARY] ,
	CONSTRAINT [UK_principal_name] UNIQUE  NONCLUSTERED 
	(
		[principal_id],
		[name]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO