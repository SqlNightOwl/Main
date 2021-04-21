CREATE TABLE [customers].[PriceCapPropertiesHistory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[PriceCapIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[LogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapPropertiesHistory_LogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapPropertiesHistory_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_PriceCapPropertiesHistory_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_PriceCapPropertiesHistory_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[PriceCapPropertiesHistory] ADD CONSTRAINT [PK_PriceCapPropertiesHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCapPropertiesHistory_RECORDSTAMP] ON [customers].[PriceCapPropertiesHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
