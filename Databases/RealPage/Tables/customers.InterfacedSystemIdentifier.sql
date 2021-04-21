CREATE TABLE [customers].[InterfacedSystemIdentifier]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RecordType] AS (case when nullif([PropertyIDSeq],'') IS NULL then 'AHOFF' else 'APROP' end),
[InterfacedSystemID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InterfacedSystemClientType] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[InterfacedSystemCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[InterfacedSystemIDTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByUserIDSeq] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InterfacedSystemIdentifier_CreatedDate] DEFAULT (getdate()),
[ModifiedByUserIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_InterfacedSystemIdentifier_ModifiedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InterfacedSystemIdentifier_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InterfacedSystemIdentifier_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[InterfacedSystemIdentifier] ADD CONSTRAINT [PK_InterfacedSystemIdentifier] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IXN_UniqueIndex_InterfacedSystemIdentifier] ON [customers].[InterfacedSystemIdentifier] ([CompanyIDSeq], [PropertyIDSeq], [RecordType], [InterfacedSystemID], [InterfacedSystemCode], [InterfacedSystemIDTypeCode]) ON [PRIMARY]
GO
ALTER TABLE [customers].[InterfacedSystemIdentifier] WITH NOCHECK ADD CONSTRAINT [InterfacedSystemIdentifier_has_Company] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[InterfacedSystemIdentifier] WITH NOCHECK ADD CONSTRAINT [InterfacedSystemIdentifier_has_InterfacedSystem] FOREIGN KEY ([InterfacedSystemCode]) REFERENCES [customers].[InterfacedSystem] ([Code])
GO
ALTER TABLE [customers].[InterfacedSystemIdentifier] WITH NOCHECK ADD CONSTRAINT [InterfacedSystemIdentifier_has_InterfacedSystemIDType] FOREIGN KEY ([InterfacedSystemIDTypeCode]) REFERENCES [customers].[InterfacedSystemIDType] ([Code])
GO
ALTER TABLE [customers].[InterfacedSystemIdentifier] WITH NOCHECK ADD CONSTRAINT [InterfacedSystemIdentifier_has_Property] FOREIGN KEY ([PropertyIDSeq]) REFERENCES [customers].[Property] ([IDSeq])
GO
EXEC sp_addextendedproperty N'MS_Description', N'CompanyIDSeq of OMS company record.FK to Company table. Always filled in for both Company and Property record.', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'CompanyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Primary Key.Unique auto incremented value', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'InterfacedSystemClientType to record External Systems Client type if different from OMS defined AHOFF and APROP.  Eg: Supplier which denotes Commercial type in Company with CommercialFlag set as 1. This column is useful for Migration needs.', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'InterfacedSystemClientType'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Code of External System Name that Interfaces with OMS. FK to InterfacedSystem.', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'InterfacedSystemCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'InterfacedSystemID to exact and actual Unique ID of External System for a given InterfacedSystemIDTypeCode. eg External System AccountID, Billing ID etc', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'InterfacedSystemID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Code of ID Name of External System Name that Interfaces with OMS. FK to InterfacedSystem.', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'InterfacedSystemIDTypeCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'PropertyIDSeq of OMC Property record.FK to Property Table. Always filled for Property Record. NULL for True Company record.', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'PropertyIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Type define the nature of record. For Company record, propertyID is null and hence it is AHOFF (Home office account). For Property record it is APROP (Property Account)', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIdentifier', 'COLUMN', N'RecordType'
GO
