CREATE TABLE [customers].[InterfacedSystem]
(
[Code] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_InterfacedSystem_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_InterfacedSystem_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_InterfacedSystem_SystemLogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [customers].[InterfacedSystem] ADD CONSTRAINT [PK_InterfacedSystemType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_InterfacedSystem_Name] ON [customers].[InterfacedSystem] ([Name]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Primary Key.Unique identifier code for External System that interface with OMS for Billing', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystem', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Brief Description of External System that Interfaces with OMS', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystem', 'COLUMN', N'Description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'External System Name that Interfaces with OMS. Eg: Velocity, OpsTech etc', 'SCHEMA', N'customers', 'TABLE', N'InterfacedSystem', 'COLUMN', N'Name'
GO
