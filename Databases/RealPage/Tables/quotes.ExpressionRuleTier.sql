CREATE TABLE [quotes].[ExpressionRuleTier]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[ERuleIDSeq] [bigint] NOT NULL,
[TierLevel] [bigint] NOT NULL,
[ActiveFlag] [int] NOT NULL CONSTRAINT [DF_ExpressionRuleTier_ActiveFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ExpressionRuleTier_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ExpressionRuleTier_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ExpressionRuleTier_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[ExpressionRuleTier] ADD CONSTRAINT [PK_ExpressionRuleTier] PRIMARY KEY CLUSTERED  ([IDSeq], [ERuleIDSeq]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[ExpressionRuleTier] WITH NOCHECK ADD CONSTRAINT [QUOTES_has_ExpressionRuleTier] FOREIGN KEY ([ERuleIDSeq]) REFERENCES [quotes].[ExpressionRule] ([ERuleIDSeq])
GO
