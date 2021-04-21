CREATE TABLE [customers].[TWT_SiebelPushSelfManagedSitesCompanies]
(
[IDSEQ] [int] NOT NULL IDENTITY(1, 1),
[OMSCOMPANYID] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OMSACCOUNTID] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial PMC Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current PMC Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OMS Company ID] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial Siebel PMC ID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current SiebelPMC ID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial Siebel Row ID] [varchar] (40) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current Siebel Row ID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial Address] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current Address] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial City] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current City] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial State] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current State] [char] (2) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Initial Zip] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Current Zip] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL
) ON [PRIMARY]
GO
ALTER TABLE [customers].[TWT_SiebelPushSelfManagedSitesCompanies] ADD CONSTRAINT [PK_TWT_SiebelPushSelfManagedSitesCompanies] PRIMARY KEY CLUSTERED  ([IDSEQ]) ON [PRIMARY]
GO
