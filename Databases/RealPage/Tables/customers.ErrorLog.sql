CREATE TABLE [customers].[ErrorLog]
(
[IDSeq] [numeric] (10, 0) NOT NULL IDENTITY(1, 1),
[LogDate] [datetime] NOT NULL CONSTRAINT [DF__ErrorLog__LogDat__173876EA] DEFAULT (getdate()),
[ApplicationUserName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ErrorMessage] [varchar] (2000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SourceQueryString] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SourceMethod] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DBServerName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DBDataBaseName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DBQuery] [varchar] (3000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StackTrace] [text] COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AdditionalComments] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ExceptionType] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SqlErrorNumber] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ErrorLog_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ErrorLog_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ErrorLog_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [customers].[ErrorLog] ADD CONSTRAINT [PK__ErrorLog__164452B1] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ErrorLog_RECORDSTAMP] ON [customers].[ErrorLog] ([RECORDSTAMP]) ON [PRIMARY]
GO
