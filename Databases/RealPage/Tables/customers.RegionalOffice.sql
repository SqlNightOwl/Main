CREATE TABLE [customers].[RegionalOffice]
(
[RegionalOfficeIDSeq] [bigint] NOT NULL,
[RegionalOfficeName] AS (CONVERT([varchar](50),('Regional Office :'+case when len([RegionalOfficeIDSeq])=(1) then '0' else '' end)+CONVERT([varchar](50),[RegionalOfficeIDSeq],(0)),(0))),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_RegionalOffice_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_RegionalOffice_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_RegionalOffice_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[RegionalOffice] ADD CONSTRAINT [PK_RegionalOffice] PRIMARY KEY CLUSTERED  ([RegionalOfficeIDSeq]) ON [PRIMARY]
GO
