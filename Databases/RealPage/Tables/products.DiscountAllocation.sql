CREATE TABLE [products].[DiscountAllocation]
(
[Code] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DiscountAllocation_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DiscountAllocation_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DiscountAllocation_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[DiscountAllocation] ADD CONSTRAINT [PK_DiscountAllocation] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_DiscountAllocation_RECORDSTAMP] ON [products].[DiscountAllocation] ([RECORDSTAMP]) ON [PRIMARY]
GO
