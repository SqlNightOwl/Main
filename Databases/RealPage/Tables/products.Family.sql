CREATE TABLE [products].[Family]
(
[Code] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SortSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[EpicorPostingCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Family_EpicorPostingCode] DEFAULT ('RPI'),
[TaxwareCompanyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Family_TaxwareCompanyCode] DEFAULT ('01'),
[BusinessUnitLogo] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_BusinessUnitLogo_BusinessUnitLogo] DEFAULT ('RealPage'),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Family_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Family_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Family_SystemLogDate] DEFAULT (getdate()),
[PrintFamilyNoticeFlag] [int] NOT NULL CONSTRAINT [DF_Family_PrintFamilyNoticeFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [products].[Family] ADD CONSTRAINT [PK_Family] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_Family_Name] ON [products].[Family] ([Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Family_RECORDSTAMP] ON [products].[Family] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [products].[Family] WITH NOCHECK ADD CONSTRAINT [FAMILY_has_TaxwareCompanyCode] FOREIGN KEY ([TaxwareCompanyCode]) REFERENCES [products].[TaxwareCompany] ([TaxwareCompanyCode])
GO
