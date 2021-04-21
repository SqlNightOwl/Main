CREATE TABLE [customers].[AddressType]
(
[Code] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Type] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ApplyTo] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ApplyToRegionalOfficeIDSeq] [bigint] NULL,
[Name] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DisplaySortSeq] [int] NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_AddressType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_AddressType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_AddressType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[AddressType] ADD CONSTRAINT [PK_AddressType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
