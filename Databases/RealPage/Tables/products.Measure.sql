CREATE TABLE [products].[Measure]
(
[Code] [char] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DisplayFlag] [bit] NOT NULL CONSTRAINT [DF_Measure_DisplayFlag] DEFAULT ((1)),
[SortSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Measure_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Measure_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Measure_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[Measure] ADD CONSTRAINT [PK_Measure] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_Measure_Name] ON [products].[Measure] ([Name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Measure_RECORDSTAMP] ON [products].[Measure] ([RECORDSTAMP]) ON [PRIMARY]
GO
