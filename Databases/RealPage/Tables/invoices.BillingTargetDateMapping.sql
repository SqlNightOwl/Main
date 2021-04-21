CREATE TABLE [invoices].[BillingTargetDateMapping]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[BillingCycleDate] [datetime] NOT NULL,
[LeadDays] [bigint] NOT NULL,
[TargetDate] [datetime] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[BillingTargetDateMapping] ADD CONSTRAINT [PK_BillingTargetDateMapping] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_BillingTargeDateMapping_BillingCycleDate_LeadDays] ON [invoices].[BillingTargetDateMapping] ([BillingCycleDate], [LeadDays]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'BillingCycle Date pertaining to Mid month, End of Month corresponding to Active open BillingCycle Date in InvoiceEOMServiceControl Table', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMapping', 'COLUMN', N'BillingCycleDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'AutoIncremented Unique IDSeq. Primary Key.', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMapping', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'LeadDays integer values like 60,45,30,0,-15,-45 etc pertaining to all combinations of LeadDays in Product Charge Table.', 'SCHEMA', N'invoices', 'TABLE', N'BillingTargetDateMapping', 'COLUMN', N'LeadDays'
GO
