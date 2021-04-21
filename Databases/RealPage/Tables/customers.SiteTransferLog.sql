CREATE TABLE [customers].[SiteTransferLog]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Status] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FromCompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FromPropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ToCompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ToPropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderActivationStartDate] [datetime] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL,
[TransferDate] [datetime] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_SiteTransferLog_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_SiteTransferLog_RECORDSTAMP] ON [customers].[SiteTransferLog] ([RECORDSTAMP]) ON [PRIMARY]
GO
