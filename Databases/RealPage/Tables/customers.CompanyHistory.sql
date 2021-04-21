CREATE TABLE [customers].[CompanyHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[CompanyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SiteMasterID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PMCFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_PMCFlag] DEFAULT ((1)),
[OwnerFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_OwnerFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CompanyHistory_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_CompanyHistory_ModifiedDate] DEFAULT (getdate()),
[SiebelRowID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceTerm] [int] NULL,
[SiebelID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SignatureText] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StatusTypecode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_CompanyHistory_StatusTypecode] DEFAULT ('ACTIV'),
[LegacyRegistrationCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderSynchStartMonth] [int] NOT NULL CONSTRAINT [DF_CompanyHistory_OrderSynchStartMonth] DEFAULT ((0)),
[CustomBundlesProductBreakDownTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_CompanyHistory_CustomBundlesProductBreakDownTypeCode] DEFAULT ('NOBR'),
[EpicorCustomerCode] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CompanyHistory_LogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SeparateInvoiceByFamilyFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_SeparateInvoiceByFamilyFlag] DEFAULT ((0)),
[SendInvoiceToClientFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_SendInvoiceToClientFlag] DEFAULT ((1)),
[MultiFamilyFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_MultiFamilyFlag] DEFAULT ((1)),
[VendorFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_VendorFlag] DEFAULT ((0)),
[GSAEntityFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_GSAEntityFlag] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CompanyHistory_CreatedByIDSeq] DEFAULT ((-1)),
[OpsSupplierFlag] [bit] NOT NULL CONSTRAINT [DF_CompanyHistory_OpsSupplierFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [customers].[CompanyHistory] ADD CONSTRAINT [PK_CompanyHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CompanyHistory_RECORDSTAMP] ON [customers].[CompanyHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
