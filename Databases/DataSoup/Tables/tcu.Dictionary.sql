use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Dictionary]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[Dictionary]
GO
CREATE TABLE [tcu].[Dictionary] (
	[Application] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Name] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Value] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ValueType] [ut_ValueType] NOT NULL ,
	[Description] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_Dictionary] PRIMARY KEY  CLUSTERED 
	(
		[Application],
		[Name]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_Dictionary_Value] CHECK (case [ValueType] when 'string' then case len(rtrim(isnull([Value],''))) when (0) then (1) else (0) end when 'list' then case len(rtrim(isnull([Value],''))) when (0) then (1) else (0) end when 'number' then abs(isnumeric([Value])-(1)) when 'boolean' then case when [Value]='1' OR [Value]='0' then (0) else (1) end when 'datetime' then abs(isdate([Value])-(1)) else (1) end=(0))
) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[Dictionary].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[Dictionary].[CreatedOn]'
GO
EXEC sp_bindrule N'[dbo].[ck_ValueType]', N'[Dictionary].[ValueType]'
GO
EXEC sp_bindefault N'[dbo].[df_ValueType]', N'[Dictionary].[ValueType]'
GO
setuser
GO