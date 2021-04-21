CREATE TABLE [invoices].[InvoiceEOMRunLog]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[AccountIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PropertyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderItemIDSeq] [bigint] NULL,
[BeforeEOMBillingPeriodFromDate] [datetime] NULL,
[BeforeEOMBillingPeriodToDate] [datetime] NULL,
[BillingCycleDate] [datetime] NULL,
[EOMRunType] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[EOMRunBatchNumber] [bigint] NOT NULL CONSTRAINT [DF_InvoiceEOMRunLog_RunBatchNumber] DEFAULT ((0)),
[EOMRunStatus] [int] NOT NULL CONSTRAINT [DF_InvoiceEOMRunLog_EOMRunStatus] DEFAULT ((0)),
[EOMRunDatetime] [datetime] NULL,
[ErrorMessage] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceEOMRunLog_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_InvoiceEOMRunLog_ModifiedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceEOMRunLog] ADD CONSTRAINT [PK_InvoiceEOMRunLog] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_InvoiceEOMRunLog_AccountIDSeq] ON [invoices].[InvoiceEOMRunLog] ([AccountIDSeq], [CompanyIDSeq], [PropertyIDSeq], [OrderIDSeq]) INCLUDE ([BillingCycleDate], [EOMRunBatchNumber], [EOMRunDatetime], [EOMRunStatus], [EOMRunType], [ErrorMessage]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'AccountIDSeq of the Recordto be Invoiced', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'AccountIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This is the last Billing Period From Date of the OrderitemID Record before Invoicing happens', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'BeforeEOMBillingPeriodFromDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This is the last Billing Period To Date of the OrderitemID Record before Invoicing happens', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'BeforeEOMBillingPeriodToDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Billing Cycle Date pertaining to current Open Billing cylce date from InvoiceEOMServiceControl Table for which EOM Invoicing is run.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'BillingCycleDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'CompanyIDSeq of Record to be Invoiced', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'CompanyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Created By UserID. Default is NULL as This table is used by internal process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'CreatedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record creation date. Default is system date.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'BatchNumber of the Run. Generated from EOM Program as Max(RunBatchNumber) + 1 from InvoiceEOMServiceControl Table.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'EOMRunBatchNumber'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This is updated by EOM Invoicing Engine as the exact datetime when this record is picked up for Invoicing.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'EOMRunDatetime'
GO
EXEC sp_addextendedproperty N'MS_Description', N'RunStatus denotes status of the run. 0 denotes yet to picked up for Invoicing. 1 denotes Success. 2 denotes failure.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'EOMRunStatus'
GO
EXEC sp_addextendedproperty N'MS_Description', N'EOMRunType : NewContractsBilling, RecurringBilling, TransactionalBilling Etc', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'EOMRunType'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Error Message If any, when status is failed.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'ErrorMessage'
GO
EXEC sp_addextendedproperty N'MS_Description', N'AutoIncremented IDSeq of InvoiceEOMRunlog table. Primary Key', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified By UserID. Default is NULL as This table is used by internal process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'ModifiedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified date. Default is system date when it gets modified.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'OrderIDSeq of Record to be Invoiced', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'OrderIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'OrderItemIDSeq of Record to be Invoice', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'OrderItemIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PropertyIDSeq of Record to be Invoiced', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'PropertyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Timestamp RECORDSTAMP.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMRunLog', 'COLUMN', N'RECORDSTAMP'
GO
