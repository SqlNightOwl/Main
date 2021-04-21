CREATE TABLE [customers].[InvoiceDeliveryExceptionRuleDetail]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[RuleIDSeq] [bigint] NOT NULL,
[RuleType] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ApplyToOMSIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToFamilyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToCategoryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToProductTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToCustomBundleFlag] [int] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetail_ApplyToCustomBundleFlag] DEFAULT ((0)),
[BillToAddressTypeCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DeliveryOptionCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetail_DeliveryOptionCode] DEFAULT ('SMAIL'),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetail_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetail_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetail_SystemLogDate] DEFAULT (getdate()),
[ShowSiteNameOnInvoiceFlag] [int] NOT NULL CONSTRAINT [DF_InvoiceDeliveryExceptionRuleDetail_ShowSiteNameOnInvoiceFlag] DEFAULT ((0)),
[RECORDCRC] AS (binary_checksum([CompanyIDSeq],[ApplyToOMSIDSeq],[ApplyToFamilyCode],[ApplyToCategoryCode],[ApplyToProductTypeCode],[ApplyToProductCode],[ApplyToCustomBundleFlag],[BillToAddressTypeCode],[DeliveryOptionCode],[ShowSiteNameOnInvoiceFlag]))
) ON [PRIMARY]
GO
ALTER TABLE [customers].[InvoiceDeliveryExceptionRuleDetail] ADD CONSTRAINT [PK_InvoiceDeliveryExceptionRuleDetail] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_InvoiceDeliveryExceptionRuleDetail_KeyColumns] ON [customers].[InvoiceDeliveryExceptionRuleDetail] ([CompanyIDSeq], [ApplyToOMSIDSeq], [ApplyToFamilyCode], [ApplyToCategoryCode], [ApplyToProductTypeCode], [ApplyToProductCode], [ApplyToCustomBundleFlag]) INCLUDE ([BillToAddressTypeCode], [DeliveryOptionCode]) ON [PRIMARY]
GO
ALTER TABLE [customers].[InvoiceDeliveryExceptionRuleDetail] WITH NOCHECK ADD CONSTRAINT [InvoiceDeliveryExceptionRuleDetail_has_RuleIDSeq_CompanyIDSeq] FOREIGN KEY ([RuleIDSeq], [CompanyIDSeq]) REFERENCES [customers].[InvoiceDeliveryExceptionRule] ([RuleIDSeq], [CompanyIDSeq])
GO
