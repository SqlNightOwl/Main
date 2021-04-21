CREATE TABLE [quotes].[QuoteSaleAgent]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ProductCode] [char] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceVersion] [numeric] (18, 0) NULL,
[SalesAgentName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CommissionPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_QuoteSaleAgent_CommissionPercent] DEFAULT ((0.00)),
[CommissionAmount] [money] NOT NULL CONSTRAINT [DF_QuoteSaleAgent_CommissionAmount] DEFAULT ((0)),
[SalesAgentIDSeq] [bigint] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteSaleAgent_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_QuoteSaleAgent_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_QuoteSaleAgent_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteSaleAgent] ADD CONSTRAINT [PK_QuoteSaleAgent] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_QuoteSaleAgent_RECORDSTAMP] ON [quotes].[QuoteSaleAgent] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[QuoteSaleAgent] WITH NOCHECK ADD CONSTRAINT [QuoteSaleAgent_has_Quote] FOREIGN KEY ([QuoteIDSeq]) REFERENCES [quotes].[Quote] ([QuoteIDSeq])
GO
