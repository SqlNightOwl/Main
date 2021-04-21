CREATE TABLE [invoices].[CreditType]
(
[Code] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CreditType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CreditType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CreditType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[CreditType] ADD CONSTRAINT [PK_CreditType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CreditType_RECORDSTAMP] ON [invoices].[CreditType] ([RECORDSTAMP]) ON [PRIMARY]
GO
