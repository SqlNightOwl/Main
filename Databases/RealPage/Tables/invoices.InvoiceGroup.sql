CREATE TABLE [invoices].[InvoiceGroup]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OrderGroupIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceGroup_OrderGroupIDSeq] DEFAULT ((0)),
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ILFChargeAmount] [money] NOT NULL CONSTRAINT [DF_InvoiceGroup_ILFChargeAmount] DEFAULT ((0)),
[AccessChargeAmount] [money] NOT NULL CONSTRAINT [DF_InvoiceGroup_AccessChargeAmount] DEFAULT ((0)),
[TransactionChargeAmount] [money] NOT NULL CONSTRAINT [DF_InvoiceGroup_TransactionChargeAmount] DEFAULT ((0)),
[CreditAmount] [money] NOT NULL CONSTRAINT [DF_InvoiceGroup_CreditAmount] DEFAULT ((0)),
[CustomBundleNameEnabledFlag] [bit] NOT NULL CONSTRAINT [DF__InvoiceGr__Custo__5A254709] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceGroup_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceGroup_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceGroup_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceGroup] ADD CONSTRAINT [PK_InvoiceGroup] PRIMARY KEY CLUSTERED  ([IDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_InvoiceGroup_InvoiceKeyColumns] ON [invoices].[InvoiceGroup] ([InvoiceIDSeq] DESC, [OrderIDSeq] DESC, [OrderGroupIDSeq] DESC) INCLUDE ([CreatedDate], [CustomBundleNameEnabledFlag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_InvoiceGroup_OrderKeyColumns] ON [invoices].[InvoiceGroup] ([OrderIDSeq] DESC, [OrderGroupIDSeq] DESC) INCLUDE ([CreatedDate], [CustomBundleNameEnabledFlag], [InvoiceIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_InvoiceGroup_RECORDSTAMP] ON [invoices].[InvoiceGroup] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceGroup] WITH NOCHECK ADD CONSTRAINT [InvoiceGroup_has_Invoice] FOREIGN KEY ([InvoiceIDSeq]) REFERENCES [invoices].[Invoice] ([InvoiceIDSeq])
GO
