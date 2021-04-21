CREATE TABLE [documents].[AgreementNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Code] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_AgreementNote_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_AgreementNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_AgreementNote_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
