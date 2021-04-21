CREATE TABLE [customers].[MigrationOrders]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[SystemID] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SiteName] [varchar] (150) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProductName] [varchar] (150) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ProductDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderItemStatus] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ChargeType] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Measure] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Frequency] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Quantity] [int] NULL,
[ItemCharge] [money] NULL,
[NetChargeAmount] [money] NULL,
[ContractStartDate] [datetime] NULL,
[ContractEndDate] [datetime] NULL,
[ActivationDate] [datetime] NULL,
[LastBilledThroughDate] [datetime] NULL,
[BillPMC] [bit] NULL,
[ExceptionID] [int] NULL,
[ImportDate] [datetime] NULL,
[OrderIDSeq] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderItemID] [int] NULL,
[ProductCode] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Batch] [int] NULL
) ON [PRIMARY]
GO
