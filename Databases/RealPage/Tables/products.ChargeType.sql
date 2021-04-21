CREATE TABLE [products].[ChargeType]
(
[Code] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SortSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ChargeType_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ChargeType_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ChargeType_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[ChargeType] ADD CONSTRAINT [PK_FeeType] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_ChargeType_Name] ON [products].[ChargeType] ([Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_ChargeType_RECORDSTAMP] ON [products].[ChargeType] ([RECORDSTAMP]) ON [PRIMARY]
GO
