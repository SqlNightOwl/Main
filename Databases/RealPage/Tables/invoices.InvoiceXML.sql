CREATE TABLE [invoices].[InvoiceXML]
(
[VersionNumber] [bigint] NOT NULL,
[InvoiceIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[BillingCycleDate] [datetime] NOT NULL,
[AccountIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CustomerIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceXML] [xml] NOT NULL,
[OutboundProcessStatus] [int] NOT NULL CONSTRAINT [DF_InvoiceXML_OutboundProcessStatus] DEFAULT ((0)),
[InboundProcessStatus] [int] NOT NULL CONSTRAINT [DF_InvoiceXML_InboundProcessStatus] DEFAULT ((0)),
[ErrorText] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PrintFlag] [bit] NOT NULL CONSTRAINT [DF_InvoiceXML_PrintFlag] DEFAULT ((0)),
[EmailFlag] [bit] NOT NULL CONSTRAINT [DF_InvoiceXML_EmailFlag] DEFAULT ((0)),
[BusinessUnit] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SendToEmailAddress] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InvoiceTotal] [money] NOT NULL CONSTRAINT [DF_InvoiceXML_InvoiceTotal] DEFAULT ((0.00)),
[ProductCount] [int] NOT NULL CONSTRAINT [DF_InvoiceXML_ProductCount] DEFAULT ((0)),
[LineItemCount] [int] NOT NULL CONSTRAINT [DF_InvoiceXML_LineItemCount] DEFAULT ((0)),
[Lanvera_DeliveryMethod] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Lanvera_LineItemCount] [int] NULL,
[Lanvera_InvoiceTotal] [money] NULL,
[DocumentIDSeq] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[BatchGenerationID] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceXML_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_InvoiceXML_ModifiedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceXML] ADD CONSTRAINT [PK_InvoiceXML] PRIMARY KEY CLUSTERED  ([VersionNumber], [InvoiceIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_InvoiceXML_BillingCycle] ON [invoices].[InvoiceXML] ([BillingCycleDate] DESC, [BatchGenerationID] DESC, [BusinessUnit]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_InvoiceXML_Customer] ON [invoices].[InvoiceXML] ([CustomerIDSeq], [AccountIDSeq], [PropertyIDSeq], [DocumentIDSeq], [BillingCycleDate]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[InvoiceXML] WITH NOCHECK ADD CONSTRAINT [InvoiceXML_has_Invoice] FOREIGN KEY ([InvoiceIDSeq]) REFERENCES [invoices].[Invoice] ([InvoiceIDSeq])
GO
EXEC sp_addextendedproperty N'MS_Description', N'AccountID pertaining to InvoiceID', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'AccountIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This is unique Guid identifying all records for a given Batch Run. Inserted as part of Inbound process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'BatchGenerationID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Billing Cycle Date of Invoice.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'BillingCycleDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Business unit denoting RealPage, OpsTech', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'BusinessUnit'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Created By UserID. Default is NULL as This table is used by internal process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'CreatedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record creation date. Default is system date.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'CustomerID of Company.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'CustomerIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'DocumentID of OMS pertaining to InvoiceID. Updated by Inbound Process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'DocumentIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'EmailFlag setting of Invoice.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'EmailFlag'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ErrorText containing Full Description of Error Text. Applicable for Inbound or Outbound process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'ErrorText'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Status of Inbound process frm Lanvera. 0 is Unprocessed.1 is Success. 2 is Failure. 5 is inProcess.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'InboundProcessStatus'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Unique InvoiceID. Primary Key', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'InvoiceIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit Column: Total amount of Invoice. This is recorded by Outbound process and used to validate against Lanvera_InvoiceTotal when Invoice is recieved from Lanvera.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'InvoiceTotal'
GO
EXEC sp_addextendedproperty N'MS_Description', N'XML of Entire Invoice in agreed upon format with Lanvera. This XML is sent to Lanvera for Invoice Printing.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'InvoiceXML'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit Column: Lanveras Delivery method. This should coincide with Outbound process delivery method.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'Lanvera_DeliveryMethod'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit Column: Lanvera Invoice InvoiceTotal. This should coincide with InvoiceTotal of Outbound Process and validated against InvoiceTotal', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'Lanvera_InvoiceTotal'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit Column: Lanvera Invoice Line Item Count. This should coincide with LineItemCount of Outbound Process and validated against LineItemCount', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'Lanvera_LineItemCount'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit Column: Total line items on the Invoice. This is recorded by Outbound process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'LineItemCount'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified By UserID. Default is NULL as This table is used by internal process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'ModifiedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Modified date. Default is system date when it gets modified.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Status of Invoice XML generation process for Outbound. 0 is Unprocessed.1 is Success. 2 is Failure. 5 is inProcess.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'OutboundProcessStatus'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PrintFlag  setting of Invoice.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'PrintFlag'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit Column: Total Product Count on the Invoice. This is recorded by Outbound process.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'ProductCount'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PropertyIDSeq Pertaining to InvoiceID', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'PropertyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Record Timestamp RECORDSTAMP.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'RECORDSTAMP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'If EmailFlag setting of Invoice is 1,SendToEmailAddress denotes comma separated recipient email list.', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'SendToEmailAddress'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Unique Version Number of a given InvoiceID for a given run. Primary Key', 'SCHEMA', N'invoices', 'TABLE', N'InvoiceXML', 'COLUMN', N'VersionNumber'
GO
