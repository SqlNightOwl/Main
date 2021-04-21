CREATE TABLE [quotes].[BBQRequest]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[BatchID] [bigint] NOT NULL,
[Kind] [int] NOT NULL,
[Note] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Created] [datetime] NOT NULL,
[Completed] [datetime] NOT NULL,
[Parameter] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [quotes].[BBQRequest] ADD CONSTRAINT [PK_BBQRequest] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [quotes].[BBQRequest] WITH NOCHECK ADD CONSTRAINT [BBQRequest_has_BBQBatch] FOREIGN KEY ([BatchID]) REFERENCES [quotes].[BBQBatch] ([ID])
GO
ALTER TABLE [quotes].[BBQRequest] WITH NOCHECK ADD CONSTRAINT [BBQRequest_has_BBQRequestKind] FOREIGN KEY ([Kind]) REFERENCES [quotes].[BBQRequestKind] ([ID])
GO
