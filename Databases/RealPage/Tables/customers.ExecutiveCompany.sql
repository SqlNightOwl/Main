CREATE TABLE [customers].[ExecutiveCompany]
(
[ExecutiveCompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_ExecutiveCompany_ActiveFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ExecutiveCompany_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ExecutiveCompany_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ExecutiveCompany_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[ExecutiveCompany] ADD CONSTRAINT [PK_ExecutiveCompany] PRIMARY KEY CLUSTERED  ([CompanyIDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_ExecutiveCompany_CompanyExecutiveCompanyIDSeq] ON [customers].[ExecutiveCompany] ([CompanyIDSeq] DESC, [ExecutiveCompanyIDSeq] DESC) INCLUDE ([CompanyName]) ON [PRIMARY]
GO
ALTER TABLE [customers].[ExecutiveCompany] WITH NOCHECK ADD CONSTRAINT [ExecutiveCompany_has_CompanyIDSeq] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
