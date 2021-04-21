CREATE TABLE [customers].[InvoiceDeliveryExceptionRule]
(
[RuleIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRule_RuleIDSeq] DEFAULT ((0)),
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RuleType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RuleName] AS (CONVERT([varchar](50),('Rule :'+case when len([RuleIDSeq])=(1) then '0' else '' end)+CONVERT([varchar](50),[RuleIDSeq],(0)),(0))),
[RuleDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRule_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRule_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRule_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[InvoiceDeliveryExceptionRule] ADD CONSTRAINT [PK_InvoiceDeliveryExceptionRule] PRIMARY KEY CLUSTERED  ([RuleIDSeq], [CompanyIDSeq]) ON [PRIMARY]
GO
ALTER TABLE [customers].[InvoiceDeliveryExceptionRule] WITH NOCHECK ADD CONSTRAINT [InvoiceDeliveryExceptionRule_has_CompanyIDSeq] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
