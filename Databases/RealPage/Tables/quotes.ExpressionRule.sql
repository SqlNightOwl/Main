CREATE TABLE [quotes].[ExpressionRule]
(
[ERuleIDSeq] [bigint] NOT NULL,
[SubSystem] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ApplyToArea] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ExpressionRuleName] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Expression] [varchar] (8000) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[ActiveFlag] [int] NOT NULL CONSTRAINT [DF_ExpressionRule_ActiveFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_ExpressionRule_CreatedByIDSeq] DEFAULT ((-1)),
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_ExpressionRule_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_ExpressionRule_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[ExpressionRule] ADD CONSTRAINT [PK_ExpressionRule] PRIMARY KEY CLUSTERED  ([ERuleIDSeq]) ON [PRIMARY]
GO
