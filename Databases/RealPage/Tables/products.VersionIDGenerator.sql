CREATE TABLE [products].[VersionIDGenerator]
(
[IDSeq] [numeric] (18, 0) NOT NULL,
[VersionNumber] AS ([IDSeq]),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [products].[VersionIDGenerator] ADD CONSTRAINT [PK_VersionIDGenerator] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_VersionIDGenerator_RECORDSTAMP] ON [products].[VersionIDGenerator] ([RECORDSTAMP]) ON [PRIMARY]
GO
