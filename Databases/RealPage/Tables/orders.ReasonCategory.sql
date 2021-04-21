CREATE TABLE [orders].[ReasonCategory]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[ReasonCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[CategoryCode] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[InternalFlag] [bit] NOT NULL CONSTRAINT [DF_IDSeq_InternalFlag] DEFAULT ((1)),
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_IDSeq_ActiveFlag] DEFAULT ((1)),
[UserEditableFlag] [bit] NOT NULL CONSTRAINT [DF_IDSeq_UserEditableFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_IDSeq_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_IDSeq_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_IDSeq_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [orders].[ReasonCategory] ADD CONSTRAINT [PK_IDSeq] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IXNUQ_ReasonCategory_ReasonCode_CategoryCode] ON [orders].[ReasonCategory] ([ReasonCode], [CategoryCode]) INCLUDE ([IDSeq]) ON [PRIMARY]
GO
ALTER TABLE [orders].[ReasonCategory] WITH NOCHECK ADD CONSTRAINT [ReasonCategory_has_CategoryCode] FOREIGN KEY ([CategoryCode]) REFERENCES [orders].[Category] ([Code])
GO
ALTER TABLE [orders].[ReasonCategory] WITH NOCHECK ADD CONSTRAINT [ReasonCategory_has_ReasonCode] FOREIGN KEY ([ReasonCode]) REFERENCES [orders].[Reason] ([Code])
GO
