CREATE TABLE [customers].[CustomerOwner]
(
[CustomerIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OwnerIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_CustomerOwner_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_CustomerOwner_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_CustomerOwner_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[CustomerOwner] ADD CONSTRAINT [PK_CustomerOwner] PRIMARY KEY CLUSTERED  ([CustomerIDSeq], [OwnerIDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_CustomerOwner_RECORDSTAMP] ON [customers].[CustomerOwner] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[CustomerOwner] WITH NOCHECK ADD CONSTRAINT [CustomerOwner_has_Company1] FOREIGN KEY ([CustomerIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[CustomerOwner] WITH NOCHECK ADD CONSTRAINT [CustomerOwner_has_Company] FOREIGN KEY ([OwnerIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
