use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessParameter]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [tcu].[ProcessParameter]
GO
CREATE TABLE [tcu].[ProcessParameter] (
	[ProcessId] [smallint] NOT NULL ,
	[Parameter] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[Value] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ValueType] [ut_ValueType] NOT NULL ,
	[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[UpdatedOn] [datetime] NULL ,
	CONSTRAINT [PK_ProcessParameter] PRIMARY KEY  CLUSTERED 
	(
		[ProcessId],
		[Parameter]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_ProcessParameter_Value] CHECK (case [ValueType] when 'string' then case len(rtrim(isnull([Value],''))) when (0) then (1) else (0) end when 'list' then case len(rtrim(isnull([Value],''))) when (0) then (1) else (0) end when 'number' then abs(isnumeric([Value])-(1)) when 'boolean' then case when [Value]='1' OR [Value]='0' then (0) else (1) end when 'datetime' then abs(isdate([Value])-(1)) else (1) end=(0))
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_Parameter] ON [tcu].[ProcessParameter]([Parameter]) ON [PRIMARY]
GO
setuser N'tcu'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[ProcessParameter].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[ProcessParameter].[CreatedOn]'
GO
EXEC sp_bindrule N'[dbo].[ck_ValueType]', N'[ProcessParameter].[ValueType]'
GO
EXEC sp_bindefault N'[dbo].[df_ValueType]', N'[ProcessParameter].[ValueType]'
GO
setuser
GO