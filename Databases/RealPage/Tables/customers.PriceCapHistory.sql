CREATE TABLE [customers].[PriceCapHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DocumentIDSeq] [bigint] NULL,
[PriceCapName] [varchar] (500) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceCapBasisCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_PriceCapHistory_PriceCapBasisCode] DEFAULT ('LIST'),
[PriceCapPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_PriceCapHistory_PriceCapPercent] DEFAULT ((0.00)),
[PriceCapTerm] [int] NOT NULL CONSTRAINT [DF_PriceCapHistory_PriceCapTerm] DEFAULT ((0)),
[PriceCapStartDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapHistory_StartDate] DEFAULT (getdate()),
[PriceCapEndDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapHistory_EndDate] DEFAULT (getdate()),
[LogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapHistory_LogDate] DEFAULT (getdate()),
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF__PriceCapH__Activ__7108AC61] DEFAULT ((0)),
[CreatedByID] [bigint] NULL,
[CreatedDate] [datetime] NULL,
[SystemGeneratedPriceCapFlag] [bit] NOT NULL CONSTRAINT [DF_PriceCapHistory_SystemGeneratedPriceCapFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[PriceCapNotes] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapHistory] ADD CONSTRAINT [PK_PriceCapHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCapHistory_RECORDSTAMP] ON [customers].[PriceCapHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
