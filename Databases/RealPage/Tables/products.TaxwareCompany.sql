CREATE TABLE [products].[TaxwareCompany]
(
[TaxwareCompanyCode] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TaxwareCompany_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_TaxwareCompany_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TaxwareCompany_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[TaxwareCompany] ADD CONSTRAINT [PK_TaxwareCompany] PRIMARY KEY CLUSTERED  ([TaxwareCompanyCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_TaxwareCompany_Name] ON [products].[TaxwareCompany] ([Name]) ON [PRIMARY]
GO
