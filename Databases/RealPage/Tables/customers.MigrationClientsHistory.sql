CREATE TABLE [customers].[MigrationClientsHistory]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[IDSeq] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ImportID] [int] NULL,
[TableName] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[DateInserted] [datetime] NULL,
[AccountIDSeq] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderIDSeq] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL
) ON [PRIMARY]
GO
