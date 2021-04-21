CREATE TABLE [invoices].[TaxRecalculationStatus]
(
[LastPrequalifyDate] [datetime] NULL,
[LastCalculationDate] [datetime] NULL,
[LastAppliedDate] [datetime] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TaxRecalculationStatus_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_TaxRecalculationStatus_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TaxRecalculationStatus_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'last date/time when results of the completed recalculations were applied to the real invoice and credit memo items', 'SCHEMA', N'invoices', 'TABLE', N'TaxRecalculationStatus', 'COLUMN', N'LastAppliedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'last date/time when a batch of items had their taxes recalculated ', 'SCHEMA', N'invoices', 'TABLE', N'TaxRecalculationStatus', 'COLUMN', N'LastCalculationDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'last date/time when items were prequalified for recalculation', 'SCHEMA', N'invoices', 'TABLE', N'TaxRecalculationStatus', 'COLUMN', N'LastPrequalifyDate'
GO
