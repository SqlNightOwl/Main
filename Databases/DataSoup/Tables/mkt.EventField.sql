use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventField]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [mkt].[EventField]
GO
CREATE TABLE [mkt].[EventField] (
	[EventId] [int] NOT NULL ,
	[Field] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FieldNumber] [tinyint] NOT NULL ,
	[IsRequired] [bit] NOT NULL ,
	[FieldCaption] [varchar] (125) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[FieldType] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[ListOfValues] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[CreatedOn] [datetime] NOT NULL ,
	[CreatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[UpdatedOn] [datetime] NULL ,
	[UpdatedBy] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	CONSTRAINT [PK_EventField] PRIMARY KEY  NONCLUSTERED 
	(
		[EventId],
		[Field]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] ,
	CONSTRAINT [CK_EventField_FieldType] CHECK (case when [FieldType]='checkbox group' then (1) when [FieldType]='checkbox' then (1) when [FieldType]='date' then (1) when [FieldType]='number' then (1) when [FieldType]='radio group' then (1) when [FieldType]='select' then (1) when [FieldType]='textarea' then (1) when [FieldType]='textbox' then (1) else (0) end=(1)),
	CONSTRAINT [CK_EventField_ListOfValues] CHECK (case [FieldType] when 'checkbox group' then len([ListOfValues]) when 'image group' then len([ListOfValues]) when 'radio group' then len([ListOfValues]) when 'select' then len([ListOfValues]) else (1) end>(0))
) ON [PRIMARY]
GO
 CREATE  UNIQUE  CLUSTERED  INDEX [AK_EventField] ON [mkt].[EventField]([EventId], [FieldNumber]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
 CREATE  INDEX [FK_Event] ON [mkt].[EventField]([EventId]) WITH  FILLFACTOR = 90 ON [PRIMARY]
GO
setuser N'mkt'
GO
EXEC sp_bindefault N'[dbo].[df_UserAudit]', N'[EventField].[CreatedBy]'
GO
EXEC sp_bindefault N'[dbo].[df_DateTimeStamp]', N'[EventField].[CreatedOn]'
GO
EXEC sp_bindefault N'[dbo].[df_Zero]', N'[EventField].[IsRequired]'
GO
setuser
GO