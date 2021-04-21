CREATE TABLE [invoices].[BillingTargetDateMappingArchive]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[BillingCycleDate] [datetime] NOT NULL,
[LeadDays] [bigint] NOT NULL,
[TargetDate] [datetime] NOT NULL,
[ArchiveDate] [datetime] NOT NULL CONSTRAINT [DF_BillingTargetDateMappingArchive_ArchiveDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[BillingTargetDateMappingArchive] ADD CONSTRAINT [PK_BillingTargetDateMappingArchive] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_BillingTargeDateMapping_BillingCycleDate_LeadDays] ON [invoices].[BillingTargetDateMappingArchive] ([BillingCycleDate], [LeadDays]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Datetime Recorded by the system when archival of BillingCycle Close is recorded from InvoiceEOMServiceControl to this archive table.', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMappingArchive', 'COLUMN', N'ArchiveDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'BillingCycle Date pertaining to Mid month, End of Month corresponding to Active open BillingCycle Date in InvoiceEOMServiceControl Table', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMappingArchive', 'COLUMN', N'BillingCycleDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'AutoIncremented Unique IDSeq. Primary Key.', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMappingArchive', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'LeadDays integer values like 60,45,30,0,-15,-45 etc pertaining to all combinations of LeadDays in Product Charge Table.', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMappingArchive', 'COLUMN', N'LeadDays'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Calculated column of BillingCycleDate + LeadDays.  [LeadDays] can be a + or - integer Number', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMappingArchive', 'COLUMN', N'TargetDate'
GO
