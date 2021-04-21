CREATE TABLE [quotes].[QuoteStatus]
(
[Code] [char] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteStatus_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QuoteStatus_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteStatus_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteStatus] ADD CONSTRAINT [PK_QuoteStatus] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QuoteStatus_RECORDSTAMP] ON [quotes].[QuoteStatus] ([RECORDSTAMP]) ON [PRIMARY]
GO
