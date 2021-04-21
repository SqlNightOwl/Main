CREATE TABLE [oms].[ErrorLog]
(
[ErrorLogId] [bigint] NOT NULL IDENTITY(-9223372036854775808, 1),
[ApplicationUserName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ErrorMessage] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SourceQueryString] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SourceMethod] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBServer] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBDatabase] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBQuery] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StackTrace] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AdditionalComments] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExceptionType] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SqlErrorNumber] [int] NULL,
[RecordStamp] [timestamp] NOT NULL,
[CreatedOn] [datetime] NOT NULL CONSTRAINT [DF_ErrorLog_CreatedOn] DEFAULT (getdate()),
[CreatedById] [bigint] NOT NULL CONSTRAINT [DF_ErrorLog_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedOn] [datetime] NULL,
[ModifiedById] [bigint] NULL,
[SystemLoggedOn] [datetime] NOT NULL CONSTRAINT [DF_ErrorLog_SystemLoggedOn] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [oms].[ErrorLog] ADD CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED  ([ErrorLogId]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
