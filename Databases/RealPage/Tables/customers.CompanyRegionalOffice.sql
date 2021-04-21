CREATE TABLE [customers].[CompanyRegionalOffice]
(
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RegionalOfficeIDSeq] [bigint] NOT NULL,
[RegionalOfficeName] AS (CONVERT([varchar](50),('Regional Office :'+case when len([RegionalOfficeIDSeq])=(1) then '0' else '' end)+CONVERT([varchar](50),[RegionalOfficeIDSeq],(0)),(0))),
[RegionalOfficeDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CompanyRegionalOffice_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CompanyRegionalOffice_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CompanyRegionalOffice_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[CompanyRegionalOffice] ADD CONSTRAINT [PK_CompanyRegionalOffice] PRIMARY KEY CLUSTERED  ([CompanyIDSeq], [RegionalOfficeIDSeq]) ON [PRIMARY]
GO
ALTER TABLE [customers].[CompanyRegionalOffice] WITH NOCHECK ADD CONSTRAINT [CompanyRegionalOffice_has_CompanyIDSeq] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[CompanyRegionalOffice] WITH NOCHECK ADD CONSTRAINT [CompanyRegionalOffice_has_RegionalOfficeIDSeq] FOREIGN KEY ([RegionalOfficeIDSeq]) REFERENCES [customers].[RegionalOffice] ([RegionalOfficeIDSeq])
GO
