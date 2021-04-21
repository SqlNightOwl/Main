CREATE TABLE [orders].[TransactionImportBatchDetail]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[TransactionImportIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AccountIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanySiteMasterID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PropertySiteMasterID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderGroupIDSeq] [bigint] NULL,
[OrderItemIDSeq] [bigint] NULL,
[OrderItemTransactionIDSeq] [bigint] NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceVersion] [numeric] (18, 0) NULL,
[SourceTransactionID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[TransactionServiceDate] [datetime] NOT NULL,
[TransactionItemName] [varchar] (300) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SOCChargeAmount] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_SOCChargeAmount] DEFAULT ((0.00)),
[UserAmountOverrideFlag] [int] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_UserAmountOverrideFlag] DEFAULT ((0)),
[ListPrice] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_ListPrice] DEFAULT ((0.00)),
[ExtChargeAmount] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_ExtChargeAmount] DEFAULT ((0.00)),
[Quantity] [decimal] (18, 3) NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_Quantity] DEFAULT ((0)),
[DiscountAmount] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_DiscountAmount] DEFAULT ((0.00)),
[NetChargeAmount] [money] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_NetChargeAmount] DEFAULT ((0.00)),
[ImportableTransactionFlag] [int] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_ImportableTransactionFlag] DEFAULT ((0)),
[TranEnablerRecordFoundFlag] [int] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_TranEnablerRecordFoundFlag] DEFAULT ((0)),
[PreValidationErrorFlag] [int] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_ValidationErrorFlag] DEFAULT ((1)),
[PreValidationMessage] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DetailPostingStatusFlag] [int] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_BatchPostingStatusFlag] DEFAULT ((0)),
[DetailPostingErrorMessage] [varchar] (max) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_TransactionImportBatchDetail_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [orders].[TransactionImportBatchDetail] ADD CONSTRAINT [PK_TransactionImportBatchDetail] PRIMARY KEY CLUSTERED  ([IDSeq], [TransactionImportIDSeq]) ON [PRIMARY]
GO
ALTER TABLE [orders].[TransactionImportBatchDetail] WITH NOCHECK ADD CONSTRAINT [TransactionImportBatchDetail_has_TransactionImportIDSeq] FOREIGN KEY ([TransactionImportIDSeq]) REFERENCES [orders].[TransactionImportBatchHeader] ([IDSeq])
GO
