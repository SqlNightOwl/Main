CREATE TABLE [invoices].[BarCode]
(
[BarCodeID] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentType] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Details] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_BarCode_RECORDSTAMP] ON [invoices].[BarCode] ([RECORDSTAMP]) ON [PRIMARY]
GO
