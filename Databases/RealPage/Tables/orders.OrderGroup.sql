CREATE TABLE [orders].[OrderGroup]
(
[OrderIDSeq] [varchar] (22) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[DiscAllocationCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_OrderGroup_DiscAllocationCode] DEFAULT ('SPR'),
[ILFDiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_OrderGroup_ILFDiscountPercent] DEFAULT ((0.00)),
[ILFDiscountAmount] [money] NOT NULL CONSTRAINT [DF_OrderGroup_ILFDiscountAmount] DEFAULT ((0)),
[AccessDiscountPercent] [numeric] (30, 5) NOT NULL CONSTRAINT [DF_OrderGroup_AccessDiscountPercent] DEFAULT ((0.00)),
[AccessDiscountAmount] [money] NOT NULL CONSTRAINT [DF_OrderGroup_AccessDiscountAmount] DEFAULT ((0)),
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AllowProductCancelFlag] [bit] NOT NULL CONSTRAINT [DF_OrderGroup_AllowProductCancelFlag] DEFAULT ((1)),
[OrderGroupType] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL CONSTRAINT [DF_OrderGroup_OrderGroupType] DEFAULT ('SITE'),
[CustomBundleNameEnabledFlag] [bit] NOT NULL CONSTRAINT [DF__OrderGrou__Custo__477C86E9] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_OrderGroup_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_OrderGroup_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_OrderGroup_SystemLogDate] DEFAULT (getdate()),
[AutoFulfillILFFlag] [int] NOT NULL CONSTRAINT [DF_OrderGroup_AutoFulfillILFFlag] DEFAULT ((1)),
[AutoFulfillACSANCFlag] [int] NOT NULL CONSTRAINT [DF_OrderGroup_AutoFulfillACSANCFlag] DEFAULT ((0)),
[AutoFulfillStartDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderGroup] ADD CONSTRAINT [PK_OrderGroup] PRIMARY KEY CLUSTERED  ([OrderIDSeq], [IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_OrderGroup_RECORDSTAMP] ON [orders].[OrderGroup] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [orders].[OrderGroup] WITH NOCHECK ADD CONSTRAINT [OrderGroup_has_Order] FOREIGN KEY ([OrderIDSeq]) REFERENCES [orders].[Order] ([OrderIDSeq])
GO
