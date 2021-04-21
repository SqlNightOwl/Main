CREATE TABLE [customers].[InterfacedSystemIDType]
(
[Code] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InterfacedSystemIDType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InterfacedSystemIDType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InterfacedSystemIDType_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [customers].[InterfacedSystemIDType] ADD CONSTRAINT [PK_InterfacedSystemIDTypeType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_InterfacedSystemIDType_Name] ON [customers].[InterfacedSystemIDType] ([Name]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Primary Key.Unique identifier code for ID of External System that interface with OMS for Billing', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIDType', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Brief Description ID of External System that Interfaces with OMS', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIDType', 'COLUMN', N'Description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ID Name of External System that Interfaces with OMS. Eg: Velocity, OpsTech etc', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystemIDType', 'COLUMN', N'Name'
GO
