CREATE TABLE [customers].[Account]
(
[IDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AccountTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SiteMasterID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SiebelRowID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[EpicorCustomerCode] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StartDate] [datetime] NOT NULL,
[EndDate] [datetime] NULL,
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_Account_ActiveFlag] DEFAULT ((1)),
[BillToPMCFlag] [bit] NOT NULL CONSTRAINT [DF_Account_BillToPMCFlag] DEFAULT ((0)),
[ShipToPMCFlag] [bit] NOT NULL CONSTRAINT [DF_Account_ShipToPMCFlag] DEFAULT ((0)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Account_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL,
[SiebelID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Account_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Account_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[Account] ADD CONSTRAINT [PK_Account] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Account_CompanyPropertyID] ON [customers].[Account] ([CompanyIDSeq], [PropertyIDSeq]) INCLUDE ([AccountTypeCode], [ActiveFlag], [CreatedDate], [EndDate], [EpicorCustomerCode], [IDSeq], [ModifiedDate], [SiebelID], [SiebelRowID], [SiteMasterID], [StartDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CustomerPropertyStatus] ON [customers].[Account] ([CompanyIDSeq], [PropertyIDSeq], [ActiveFlag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Account_Accounttypecode] ON [customers].[Account] ([IDSeq], [AccountTypeCode]) INCLUDE ([ActiveFlag], [CompanyIDSeq], [CreatedDate], [EndDate], [EpicorCustomerCode], [ModifiedDate], [PropertyIDSeq], [SiebelID], [SiebelRowID], [SiteMasterID], [StartDate]) ON [PRIMARY]
GO

ALTER TABLE [customers].[Account] WITH NOCHECK ADD CONSTRAINT [Account_has_AccountType] FOREIGN KEY ([AccountTypeCode]) REFERENCES [customers].[AccountType] ([Code])
GO
ALTER TABLE [customers].[Account] WITH NOCHECK ADD CONSTRAINT [Account_has_Company] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[Account] WITH NOCHECK ADD CONSTRAINT [Account_has_Property] FOREIGN KEY ([PropertyIDSeq]) REFERENCES [customers].[Property] ([IDSeq])
GO
