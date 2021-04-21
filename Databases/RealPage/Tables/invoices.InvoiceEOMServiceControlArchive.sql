CREATE TABLE [invoices].[InvoiceEOMServiceControlArchive]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[BillingCycleDate] [datetime] NOT NULL,
[BillingCycleClosedFlag] [bit] NOT NULL CONSTRAINT [DF_InvoiceEOMServiceControlArchive_BillingCycleStatusFlag] DEFAULT ((0)),
[BillingCycleOpenedByUserIDSeq] [bigint] NOT NULL,
[BillingCycleOpenedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceEOMServiceControlArchive_BillingCycleOpenedDate] DEFAULT (getdate()),
[BillingCycleClosedByUserIDSeq] [bigint] NULL,
[BillingCycleClosedDate] [datetime] NULL,
[ArchiveDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceEOMServiceControlArchive_ArchiveDate] DEFAULT (getdate()),
[EOMEngineRunBatchNumber] [bigint] NOT NULL CONSTRAINT [DF_InvoiceEOMServiceControlArchive_RunBatchNumber] DEFAULT ((0)),
[EOMEngineBatchRunStatus] [bigint] NOT NULL CONSTRAINT [DF_InvoiceEOMServiceControlArchive_BatchRunStatus] DEFAULT ((0)),
[EOMEngineLockedFlag] [bit] NOT NULL CONSTRAINT [DF_InvoiceEOMServiceControlArchive_EOMEngineLockedFlag] DEFAULT ((0)),
[EOMEngineStartDatetime] [datetime] NULL,
[EOMEngineEndDatetime] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceEOMServiceControlArchive] ADD CONSTRAINT [PK_InvoiceEOMServiceControlArchive] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_InvoiceEOMServiceControlArchive_BillingCycleDate] ON [invoices].[InvoiceEOMServiceControlArchive] ([BillingCycleDate]) INCLUDE ([BillingCycleClosedByUserIDSeq], [BillingCycleClosedDate], [BillingCycleClosedFlag], [BillingCycleOpenedByUserIDSeq], [BillingCycleOpenedDate], [EOMEngineBatchRunStatus], [EOMEngineEndDatetime], [EOMEngineLockedFlag], [EOMEngineRunBatchNumber], [EOMEngineStartDatetime]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Datetime Recorded by the system when archival of BillingCycle Close is recorded from InvoiceEOMServiceControl to this archive table.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'ArchiveDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID of User who officially closed the Billing Cycle Period', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'BillingCycleClosedByUserIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Datetime on which this Billing cycle was officially closed.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'BillingCycleClosedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'0 by default denotes BillingCycle is open. 1 denotes BillingCycle is Closed.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'BillingCycleClosedFlag'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Current Billing Cycle Date. Cannot be null.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'BillingCycleDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'UserID of user who opened the BillingCycle Period.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'BillingCycleOpenedByUserIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Datetime on which this billing cycle period was opened.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'BillingCycleOpenedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'EOMEngineBatchRunStatus is set to 0 by default and is updated by EOM Invoicing Program as 1 if run is successful, 2 if run is unsuccessful. Not Touched by UI.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'EOMEngineBatchRunStatus'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This is the end datetime of EOM Invoicing Engine for current batch run', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'EOMEngineEndDatetime'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The flag is set exclusively by EOM Invoicing Desktop Engine. When Locked Flag is set to 1, Then EOM Invoicing processing is actively happening during which BillingCycleDate cannot be closed and advanced to a new one. Only when EOMEngineLockedFlag is set to 0 by then end of EOM invoice Process can user advance BillingCycle date.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'EOMEngineLockedFlag'
GO
EXEC sp_addextendedproperty N'MS_Description', N'EOMEngineRunBatchNumber is generated and updated by EOM Invoicing Program. Not Touched by UI.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'EOMEngineRunBatchNumber'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This is the start datetime of EOM Invoicing Engine for current batch run', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'EOMEngineStartDatetime'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Unique Auto Incremented IDSeq. Primary Key to the table.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceEOMServiceControlArchive', 'COLUMN', N'IDSeq'
GO
