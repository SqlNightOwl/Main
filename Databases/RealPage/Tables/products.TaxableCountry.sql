CREATE TABLE [products].[TaxableCountry]
(
[TaxwareCompanyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TaxableCountryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CalculateTaxFlag] [int] NOT NULL CONSTRAINT [DF_TaxableCountry_CalculateTaxFlag] DEFAULT ((1)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TaxableCountry_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_TaxableCountry_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_AddressType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[TaxableCountry] ADD CONSTRAINT [PK_TaxableCountry] PRIMARY KEY CLUSTERED  ([TaxwareCompanyCode], [TaxableCountryCode]) ON [PRIMARY]
GO
ALTER TABLE [products].[TaxableCountry] WITH NOCHECK ADD CONSTRAINT [TaxableCountry_has_TaxwareCompanyCode] FOREIGN KEY ([TaxwareCompanyCode]) REFERENCES [products].[TaxwareCompany] ([TaxwareCompanyCode])
GO
