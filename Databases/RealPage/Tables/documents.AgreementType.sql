CREATE TABLE [documents].[AgreementType]
(
[Code] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SortSeq] [int] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_AgreementType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_AgreementType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_AgreementType_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [documents].[AgreementType] ADD CONSTRAINT [PK_AgreementType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
