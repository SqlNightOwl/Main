CREATE TABLE [quotes].[BBQBatch]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[BatchKind] [int] NOT NULL,
[TotalRequestCount] [int] NOT NULL,
[CompletedRequestCount] [int] NOT NULL CONSTRAINT [DF_BBQBatch_CompletedRequestCount] DEFAULT ((0)),
[SubmitterID] [bigint] NOT NULL,
[Created] [datetime] NOT NULL,
[LastProcessed] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[BBQBatch] ADD CONSTRAINT [PK_BBQBatch] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[BBQBatch] WITH NOCHECK ADD CONSTRAINT [BBQBatch_has_BBQRequestKind] FOREIGN KEY ([BatchKind]) REFERENCES [quotes].[BBQRequestKind] ([ID])
GO
ALTER TABLE [quotes].[BBQBatch] WITH NOCHECK ADD CONSTRAINT [BBQBatch_has_BBQBatch] FOREIGN KEY ([ID]) REFERENCES [quotes].[BBQBatch] ([ID])
GO
