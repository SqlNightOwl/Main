CREATE TABLE [quotes].[Quote]
(
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CustomerIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CompanyName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Sites] [int] NOT NULL CONSTRAINT [DF_Quote_Sites] DEFAULT ((0)),
[Units] [int] NOT NULL CONSTRAINT [DF_Quote_Units] DEFAULT ((0)),
[Beds] [int] NOT NULL CONSTRAINT [DF_Quote_Beds] DEFAULT ((0)),
[OverrideFlag] [bit] NOT NULL CONSTRAINT [DF_Quote_OverrideFlag] DEFAULT ((0)),
[OverrideSites] [int] NOT NULL CONSTRAINT [DF_Quote_OverrideSites] DEFAULT ((0)),
[OverrideUnits] [int] NOT NULL CONSTRAINT [DF_Quote_OverrideUnits] DEFAULT ((0)),
[ILFExtYearChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_ILFCharge] DEFAULT ((0)),
[ILFDiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_Quote_ILFDiscountPercent] DEFAULT ((0.00)),
[ILFDiscountAmount] [money] NOT NULL CONSTRAINT [DF_Quote_ILFDiscountAmount] DEFAULT ((0.00)),
[ILFNetExtYearChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_ILFNetExtYearChargeAmount] DEFAULT ((0)),
[AccessExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessYear1Charge] DEFAULT ((0)),
[AccessExtYear2ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessYear2Charge] DEFAULT ((0)),
[AccessExtYear3ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessYear3Charge] DEFAULT ((0)),
[AccessYear1DiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_Quote_AccessYear1DiscountPercent] DEFAULT ((0.00)),
[AccessYear1DiscountAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessYear1Discount] DEFAULT ((0)),
[AccessYear2DiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_Quote_AccessYear2DiscountPercent] DEFAULT ((0.00)),
[AccessYear2DiscountAmount] [float] NOT NULL CONSTRAINT [DF_Quote_AccessYear2Discount] DEFAULT ((0)),
[AccessYear3DiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_Quote_AccessYear3DiscountPercent] DEFAULT ((0.00)),
[AccessYear3DiscountAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessYear3Discount] DEFAULT ((0)),
[AccessNetExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessNetExtYearChargeAmount] DEFAULT ((0)),
[AccessNetExtYear2ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessNetExtYear2ChargeAmount] DEFAULT ((0)),
[AccessNetExtYear3ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Quote_AccessNetExtYear3ChargeAmount] DEFAULT ((0)),
[QuoteStatusCode] [char] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByDisplayName] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ModifiedByDisplayName] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SubmittedDate] [datetime] NULL,
[AcceptanceDate] [datetime] NULL,
[ApprovalDate] [datetime] NULL,
[ExpirationDate] [datetime] NULL,
[CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Quote_CreateDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_Quote_ModifiedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[OrderActivationStartDate] [datetime] NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CSRIDSeq] [bigint] NULL,
[CancelledDate] [datetime] NULL,
[TransferredFlag] [bit] NOT NULL CONSTRAINT [DF_Quote_TransferredFlag] DEFAULT ((0)),
[QuoteTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_QUOTES_QuoteTypeCode] DEFAULT ('NEWQ'),
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Quote_SystemLogDate] DEFAULT (getdate()),
[DealDeskReferenceLevel] [int] NOT NULL CONSTRAINT [DF_Quote_DealDeskReferenceLevel] DEFAULT ((0)),
[DealDeskCurrentLevel] [int] NOT NULL CONSTRAINT [DF_Quote_DealDeskCurrentLevel] DEFAULT ((0)),
[DealDeskStatusCode] [char] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_QUOTES_DealDeskStatusCode] DEFAULT ('NSU'),
[DealDeskQueuedDate] [datetime] NULL,
[DealDeskQueuedByIDSeq] [bigint] NULL,
[DealDeskDecisionMadeBy] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DealDeskNote] [varchar] (1000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DealDeskResolvedByIDSeq] [bigint] NULL,
[DealDeskResolvedDate] [datetime] NULL,
[PrePaidFlag] [int] NOT NULL CONSTRAINT [DF_Quote_PrePaidFlag] DEFAULT ((0)),
[RequestedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ExternalQuoteFlag] [int] NOT NULL CONSTRAINT [DF_Quote_ExternalQuoteFlag] DEFAULT ((0)),
[RollbackReasonCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ExternalQuoteIIFlag] [int] NOT NULL CONSTRAINT [DF_Quote_ExternalQuoteIIFlag] DEFAULT ((0)),
[RollbackByIDSeq] [int] NULL,
[RollBackDate] [datetime] NULL,
[RECORDCRC] AS (binary_checksum([CustomerIDSeq],[CompanyName],[Sites],[Units],[Beds],[OverrideFlag],[OverrideSites],[OverrideUnits],[ILFExtYearChargeAmount],[ILFDiscountPercent],[ILFDiscountAmount],[ILFNetExtYearChargeAmount],[AccessExtYear1ChargeAmount],[AccessExtYear2ChargeAmount],[AccessExtYear3ChargeAmount],[AccessYear1DiscountPercent],[AccessYear1DiscountAmount],[AccessYear2DiscountPercent],[AccessYear2DiscountAmount],[AccessYear3DiscountPercent],[AccessYear3DiscountAmount],[AccessNetExtYear1ChargeAmount],[AccessNetExtYear2ChargeAmount],[AccessNetExtYear3ChargeAmount],[QuoteStatusCode],[QuoteTypeCode],[SubmittedDate],[ApprovalDate],[ExpirationDate],[OrderActivationStartDate],[Description],[CancelledDate],[CreatedByIDSeq],[ModifiedByIDSeq],[ModifiedDate],[PrePaidFlag],[RequestedBy],[DealDeskReferenceLevel],[DealDeskCurrentLevel],[DealDeskStatusCode],[DealDeskQueuedDate],[DealDeskQueuedByIDSeq],[DealDeskDecisionMadeBy],[DealDeskNote],[DealDeskResolvedByIDSeq],[DealDeskResolvedDate],[ExternalQuoteIIFlag],[RollbackReasonCode],[RollbackByIDSeq],[RollBackDate]))
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[Quote] ADD CONSTRAINT [PK_Quote] PRIMARY KEY CLUSTERED  ([QuoteIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_Quote_CompanyName] ON [quotes].[Quote] ([CompanyName], [QuoteStatusCode]) INCLUDE ([AcceptanceDate], [AccessExtYear1ChargeAmount], [AccessExtYear2ChargeAmount], [AccessExtYear3ChargeAmount], [AccessNetExtYear1ChargeAmount], [AccessNetExtYear2ChargeAmount], [AccessNetExtYear3ChargeAmount], [AccessYear1DiscountAmount], [AccessYear1DiscountPercent], [AccessYear2DiscountAmount], [AccessYear2DiscountPercent], [AccessYear3DiscountAmount], [AccessYear3DiscountPercent], [ApprovalDate], [Beds], [CancelledDate], [CreateDate], [CreatedBy], [CreatedByDisplayName], [CreatedByIDSeq], [CSRIDSeq], [CustomerIDSeq], [Description], [ExpirationDate], [ILFDiscountAmount], [ILFDiscountPercent], [ILFExtYearChargeAmount], [ILFNetExtYearChargeAmount], [ModifiedBy], [ModifiedByDisplayName], [ModifiedByIDSeq], [ModifiedDate], [OverrideFlag], [OverrideSites], [OverrideUnits], [QuoteIDSeq], [QuoteTypeCode], [Sites], [SubmittedDate], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_Quote_CreateDate] ON [quotes].[Quote] ([CreateDate], [ExpirationDate]) INCLUDE ([AcceptanceDate], [AccessExtYear1ChargeAmount], [AccessExtYear2ChargeAmount], [AccessExtYear3ChargeAmount], [AccessNetExtYear1ChargeAmount], [AccessNetExtYear2ChargeAmount], [AccessNetExtYear3ChargeAmount], [AccessYear1DiscountAmount], [AccessYear1DiscountPercent], [AccessYear2DiscountAmount], [AccessYear2DiscountPercent], [AccessYear3DiscountAmount], [AccessYear3DiscountPercent], [ApprovalDate], [Beds], [CancelledDate], [CompanyName], [CreatedBy], [CreatedByDisplayName], [CreatedByIDSeq], [CSRIDSeq], [CustomerIDSeq], [Description], [ILFDiscountAmount], [ILFDiscountPercent], [ILFExtYearChargeAmount], [ILFNetExtYearChargeAmount], [ModifiedBy], [ModifiedByDisplayName], [ModifiedByIDSeq], [ModifiedDate], [OverrideFlag], [OverrideSites], [OverrideUnits], [QuoteIDSeq], [QuoteStatusCode], [QuoteTypeCode], [Sites], [SubmittedDate], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Quotes_Quote_CustomerIDSeq] ON [quotes].[Quote] ([CustomerIDSeq], [ModifiedByIDSeq]) INCLUDE ([AcceptanceDate], [AccessExtYear1ChargeAmount], [AccessExtYear2ChargeAmount], [AccessExtYear3ChargeAmount], [AccessNetExtYear1ChargeAmount], [AccessNetExtYear2ChargeAmount], [AccessNetExtYear3ChargeAmount], [AccessYear1DiscountAmount], [AccessYear1DiscountPercent], [AccessYear2DiscountAmount], [AccessYear2DiscountPercent], [AccessYear3DiscountAmount], [AccessYear3DiscountPercent], [ApprovalDate], [Beds], [CancelledDate], [CompanyName], [CreateDate], [CreatedBy], [CreatedByDisplayName], [CreatedByIDSeq], [CSRIDSeq], [Description], [ExpirationDate], [ILFDiscountAmount], [ILFDiscountPercent], [ILFExtYearChargeAmount], [ILFNetExtYearChargeAmount], [ModifiedBy], [ModifiedByDisplayName], [ModifiedDate], [OverrideFlag], [OverrideSites], [OverrideUnits], [QuoteIDSeq], [QuoteStatusCode], [QuoteTypeCode], [Sites], [SubmittedDate], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Quote_RECORDSTAMP] ON [quotes].[Quote] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[Quote] WITH NOCHECK ADD CONSTRAINT [QUOTES_has_DealDeskStatusCode] FOREIGN KEY ([DealDeskStatusCode]) REFERENCES [quotes].[QuoteStatus] ([Code])
GO
ALTER TABLE [quotes].[Quote] WITH NOCHECK ADD CONSTRAINT [Quote_has_QuoteStatus] FOREIGN KEY ([QuoteStatusCode]) REFERENCES [quotes].[QuoteStatus] ([Code])
GO
ALTER TABLE [quotes].[Quote] WITH NOCHECK ADD CONSTRAINT [QUOTES_has_QuoteTypeCode] FOREIGN KEY ([QuoteTypeCode]) REFERENCES [quotes].[QuoteType] ([Code])
GO
