CREATE TABLE [quotes].[DirectReports]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[Name] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[DirectReports] ADD CONSTRAINT [PK_DirectReports] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_DirectReports_RECORDSTAMP] ON [quotes].[DirectReports] ([RECORDSTAMP]) ON [PRIMARY]
GO
