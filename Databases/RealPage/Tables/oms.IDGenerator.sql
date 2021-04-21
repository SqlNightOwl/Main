CREATE TABLE [oms].[IDGenerator]
(
[IdGeneratorCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IdNumber] [numeric] (6, 0) NOT NULL,
[IdGenerator] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[GeneratedOn] [smalldatetime] NOT NULL,
[IdGeneratorSeq] AS (CONVERT([char](11),([IdGeneratorCd]+CONVERT([char](4),[GeneratedOn],(12)))+right('000000'+rtrim(CONVERT([char](6),[IdNumber],0)),(6)),0)),
[RecordStamp] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [oms].[IDGenerator] ADD CONSTRAINT [CK_IDGenerator_IdGeneratorCd] CHECK (([IdGeneratorCd] like '[A-Z]'))
GO
ALTER TABLE [oms].[IDGenerator] ADD CONSTRAINT [CK_IDGenerator_IDSeq] CHECK (([IdNumber]>(-1)))
GO
ALTER TABLE [oms].[IDGenerator] ADD CONSTRAINT [PK_IDGenerator] PRIMARY KEY CLUSTERED  ([IdGeneratorCd]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_IDGenerator] ON [oms].[IDGenerator] ([IdGenerator]) INCLUDE ([GeneratedOn], [IdGeneratorCd], [IdNumber]) ON [PRIMARY]
GO
