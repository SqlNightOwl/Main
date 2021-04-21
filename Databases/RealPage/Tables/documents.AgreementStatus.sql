CREATE TABLE [documents].[AgreementStatus]
(
[Code] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SORTSeq] [int] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_AgreementStatus_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_AgreementStatus_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_AgreementStatus_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[AgreementStatus] ADD CONSTRAINT [PK_AgreementStatus] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
