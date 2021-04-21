CREATE TABLE [quotes].[MPFPublicationYear]
(
[PublicationYear] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_MPFPublicationYear_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_MPFPublicationYear_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_MPFPublicationYear_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [quotes].[MPFPublicationYear] ADD CONSTRAINT [PK_MPFPublicationYear] PRIMARY KEY CLUSTERED  ([PublicationYear]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_MPFPublicationYear_RECORDSTAMP] ON [quotes].[MPFPublicationYear] ([RECORDSTAMP]) ON [PRIMARY]
GO
