CREATE TABLE [products].[Frequency]
(
[Code] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DisplayFlag] [bit] NOT NULL CONSTRAINT [DF_Frequency_DisplayFlag] DEFAULT ((1)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Frequency_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Frequency_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Frequency_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[Frequency] ADD CONSTRAINT [PK_Frequency] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_Frequency_Name] ON [products].[Frequency] ([Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Frequency_RECORDSTAMP] ON [products].[Frequency] ([RECORDSTAMP]) ON [PRIMARY]
GO
