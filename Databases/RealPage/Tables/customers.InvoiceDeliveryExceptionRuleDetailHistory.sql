CREATE TABLE [customers].[InvoiceDeliveryExceptionRuleDetailHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[HistoryRevisionID] [bigint] NOT NULL,
[RuleIDSeq] [bigint] NOT NULL,
[RuleType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ApplyToOMSIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToFamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToCategoryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToProductTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToCustomBundleFlag] [int] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetailHistory_ApplyToCustomBundleFlag] DEFAULT ((0)),
[BillToAddressTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DeliveryOptionCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetailHistory_DeliveryOptionCode] DEFAULT ('SMAIL'),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetailHistory_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetailHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetailHistory_SystemLogDate] DEFAULT (getdate()),
[ShowSiteNameOnInvoiceFlag] [int] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetailHistory_ShowSiteNameOnInvoiceFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [customers].[InvoiceDeliveryExceptionRuleDetailHistory] ADD CONSTRAINT [PK_InvoiceDeliveryExceptionRuleDetailHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_InvoiceDeliveryExceptionRuleDetailHistory_KeyColumns] ON [customers].[InvoiceDeliveryExceptionRuleDetailHistory] ([CompanyIDSeq]) INCLUDE ([BillToAddressTypeCode], [DeliveryOptionCode]) ON [PRIMARY]
GO
