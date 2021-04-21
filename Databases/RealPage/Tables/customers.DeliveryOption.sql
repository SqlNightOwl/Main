CREATE TABLE [customers].[DeliveryOption]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[Code] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_DeliveryOption_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_DeliveryOption_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_DeliveryOption_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[DeliveryOption] ADD CONSTRAINT [PK_DeliveryOption] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_DeliveryOption_Name] ON [customers].[DeliveryOption] ([Name]) ON [PRIMARY]
GO
