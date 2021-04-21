CREATE TABLE [customers].[PropertyUnitHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PMCIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PreviousUnits] [int] NOT NULL CONSTRAINT [DF__PropertyH__Previ__7837FA39] DEFAULT ((0)),
[PreviousBeds] [int] NOT NULL CONSTRAINT [DF__PropertyH__Previ__792C1E72] DEFAULT ((0)),
[PreviousPPUPercentage] [int] NOT NULL CONSTRAINT [DF__PropertyH__Previ__7A2042AB] DEFAULT ((0)),
[CurrentUnits] [int] NOT NULL CONSTRAINT [DF__PropertyH__Curre__7B1466E4] DEFAULT ((0)),
[CurrentBeds] [int] NOT NULL CONSTRAINT [DF__PropertyH__Curre__7C088B1D] DEFAULT ((0)),
[CurrentPPUPercentage] [int] NOT NULL CONSTRAINT [DF__PropertyH__Curre__7CFCAF56] DEFAULT ((0)),
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_PropertyHistory_ModifiedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PropertyUnitHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PropertyUnitHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[PropertyUnitHistory] ADD CONSTRAINT [PK_PropertyHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PropertyUnitHistory_RECORDSTAMP] ON [customers].[PropertyUnitHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[PropertyUnitHistory] WITH NOCHECK ADD CONSTRAINT [PropertyHistory_has_PropertyIDSeq] FOREIGN KEY ([PropertyIDSeq]) REFERENCES [customers].[Property] ([IDSeq])
GO
