CREATE TABLE [docs].[FaxActivity]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[JobID] [int] NULL,
[DocumentIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FaxTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FaxStatusCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FilePath] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PageCount] [int] NULL,
[FaxNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[FaxRecipient] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_FaxActivity_CreatedDate] DEFAULT (getdate()),
[CreatedBy] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_FaxActivity_ModifiedDate] DEFAULT (getdate()),
[IsActive] [bit] NULL CONSTRAINT [DF_FaxActivity_IsActive] DEFAULT ((1)),
[JobStatus] [int] NULL,
[ErrorDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_FaxActivity_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_FaxActivity_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_FaxActivity_RECORDSTAMP] ON [docs].[FaxActivity] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [docs].[FaxActivity] WITH NOCHECK ADD CONSTRAINT [FaxActivity_has_FaxStatus] FOREIGN KEY ([FaxStatusCode]) REFERENCES [docs].[FaxStatus] ([Code])
GO
ALTER TABLE [docs].[FaxActivity] WITH NOCHECK ADD CONSTRAINT [FaxActivity_has_FaxType] FOREIGN KEY ([FaxTypeCode]) REFERENCES [docs].[FaxType] ([Code])
GO
