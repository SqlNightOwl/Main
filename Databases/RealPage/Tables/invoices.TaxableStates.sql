CREATE TABLE [invoices].[TaxableStates]
(
[State] [char] (2) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TaxableStates_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_TaxableStates_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TaxableStates_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_TaxableStates_RECORDSTAMP] ON [invoices].[TaxableStates] ([RECORDSTAMP]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IXC_TaxableStates_State] ON [invoices].[TaxableStates] ([State]) ON [PRIMARY]
GO
