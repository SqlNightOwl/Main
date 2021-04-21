CREATE TABLE [products].[InvoiceReportMapping]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[SeparateInvoiceGroupNumber] [bigint] NOT NULL CONSTRAINT [DF_InvoiceReportMappingTable_SeparateInvoiceGroupNumber] DEFAULT ((0)),
[ReportDefinitionFile] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_InvoiceReportMappingTable_ReportDefinitionFile] DEFAULT ('Invoice1'),
[LogoDefinition] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_InvoiceReportMappingTable_LogoDefinition] DEFAULT ('RealPage'),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceReportMapping_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceReportMapping_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceReportMapping_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [products].[InvoiceReportMapping] ADD CONSTRAINT [PK_InvoiceReportMapping] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
