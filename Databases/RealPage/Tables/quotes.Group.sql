CREATE TABLE [quotes].[Group]
(
[QuoteIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[DiscAllocationCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Group_DiscAllocationCode] DEFAULT ('SPR'),
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CustomerIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OverrideFlag] [bit] NOT NULL CONSTRAINT [DF_Group_OverrideFlag] DEFAULT ((0)),
[Sites] [int] NOT NULL CONSTRAINT [DF_Group_Sites] DEFAULT ((0)),
[Units] [int] NOT NULL CONSTRAINT [DF_Group_Units] DEFAULT ((0)),
[Beds] [int] NOT NULL CONSTRAINT [DF_Group_Beds] DEFAULT ((0)),
[PPUPercentage] [int] NOT NULL CONSTRAINT [DF_Group_PPUPercentage] DEFAULT ((100)),
[ILFExtYearChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_ILFExtYearChargeAmount] DEFAULT ((0)),
[ILFDiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_Group_DiscountPercent] DEFAULT ((0.00)),
[ILFDiscountAmount] [money] NOT NULL CONSTRAINT [DF_Group_DiscountAmount] DEFAULT ((0.00)),
[ILFNetExtYearChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_ILFNetExtYearChargeAmount] DEFAULT ((0)),
[AccessExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessExtYearChargeAmount] DEFAULT ((0)),
[AccessExtYear2ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessExtYear2ChargeAmount] DEFAULT ((0)),
[AccessExtYear3ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessExtYear3ChargeAmount] DEFAULT ((0)),
[AccessDiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_Group_AccessDiscPercent] DEFAULT ((0.00)),
[AccessDiscountAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessDiscAmount] DEFAULT ((0.00)),
[AccessNetExtYear1ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessNetExtYearChargeAmount] DEFAULT ((0)),
[AccessNetExtYear2ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessNetExtYear2ChargeAmount] DEFAULT ((0)),
[AccessNetExtYear3ChargeAmount] [money] NOT NULL CONSTRAINT [DF_Group_AccessNetExtYear3ChargeAmount] DEFAULT ((0)),
[ShowDetailPriceFlag] [bit] NOT NULL CONSTRAINT [DF_Group_ShowDetailFlag] DEFAULT ((0)),
[PreConfiguredBundleCode] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PreConfiguredBundleFlag] [bit] NOT NULL CONSTRAINT [DF_Group_PreConfiguredBundleFlag] DEFAULT ((0)),
[AllowProductCancelFlag] [bit] NOT NULL CONSTRAINT [DF_Group_AllowProductCancelFlag] DEFAULT ((1)),
[GroupType] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Group_GroupType] DEFAULT ('SITE'),
[CustomBundleNameEnabledFlag] [bit] NOT NULL CONSTRAINT [DF_Group_CustomBundleNameEnabledFlag] DEFAULT ((0)),
[TransferredFlag] [bit] NOT NULL CONSTRAINT [DF_Group_TransferredFlag] DEFAULT ((0)),
[ExcludeForBookingsFlag] [bit] NOT NULL CONSTRAINT [DF_Group_ExcludeForBookingsFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Group_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Group_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Group_SystemLogDate] DEFAULT (getdate()),
[AutoFulfillILFFlag] [int] NOT NULL CONSTRAINT [DF_Group_AutoFulfillILFFlag] DEFAULT ((1)),
[AutoFulfillACSANCFlag] [int] NOT NULL CONSTRAINT [DF_Group_AutoFulfillACSANCFlag] DEFAULT ((0)),
[AutoFulfillStartDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[Group] ADD CONSTRAINT [PK_Group] PRIMARY KEY CLUSTERED  ([QuoteIDSeq], [IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Group_RECORDSTAMP] ON [quotes].[Group] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[Group] WITH NOCHECK ADD CONSTRAINT [Group_has_DiscountAllocation] FOREIGN KEY ([DiscAllocationCode]) REFERENCES [quotes].[DiscountAllocation] ([Code])
GO
