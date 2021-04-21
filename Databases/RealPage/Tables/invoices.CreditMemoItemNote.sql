CREATE TABLE [invoices].[CreditMemoItemNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[CreditMemoIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreditMemoItemIDSeq] [bigint] NOT NULL,
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MandatoryFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemoItemNote_FootNote] DEFAULT ((0)),
[PrintOnCreditMemoFlag] [bit] NOT NULL CONSTRAINT [DF_CreditMemoItemNote_PrintOnInvoiceFlag] DEFAULT ((1)),
[SortSeq] [bigint] NOT NULL CONSTRAINT [DF_CreditMemoItemNote_SortSeq] DEFAULT ((99999)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CreditMemoItemNote_CreatedDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CreditMemoItemNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CreditMemoItemNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [invoices].[CreditMemoItemNote] ADD CONSTRAINT [PK_CreditMemoItemNote] PRIMARY KEY CLUSTERED  ([IDSeq] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_CreditMemo_CreditMemoItemNote_CreditMemoIDSeq] ON [invoices].[CreditMemoItemNote] ([CreditMemoIDSeq] DESC) INCLUDE ([CreditMemoItemIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_CreditMemo_CreditMemoItemNote_CreditMemoItemIDSeq] ON [invoices].[CreditMemoItemNote] ([CreditMemoItemIDSeq] DESC) INCLUDE ([CreditMemoIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CreditMemoItemNote_RECORDSTAMP] ON [invoices].[CreditMemoItemNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [invoices].[CreditMemoItemNote] WITH NOCHECK ADD CONSTRAINT [CreditMemoItemNote_has_CreditMemo] FOREIGN KEY ([CreditMemoIDSeq]) REFERENCES [invoices].[CreditMemo] ([CreditMemoIDSeq])
GO
ALTER TABLE [invoices].[CreditMemoItemNote] WITH NOCHECK ADD CONSTRAINT [CreditMemoItemNote_has_CreditMemoItem] FOREIGN KEY ([CreditMemoItemIDSeq]) REFERENCES [invoices].[CreditMemoItem] ([IDSeq])
GO
