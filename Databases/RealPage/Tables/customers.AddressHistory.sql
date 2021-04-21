CREATE TABLE [customers].[AddressHistory]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[AddressIDSeq] [bigint] NOT NULL,
[CompanyIDSeq] [varchar] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AddressTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AddressLine1] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AddressLine2] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[City] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[County] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[State] [char] (2) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Zip] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoice1] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt1] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoice2] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt2] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneFax] [varchar] (14) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Email] [varchar] (2000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[URL] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SameAsPMCAddressFlag] [bit] NOT NULL CONSTRAINT [DF_AddressHistory_SameAsPMCAddressFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_AddressHistory_CreateDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_AddressHistory_ModifiedDate] DEFAULT (getdate()),
[AttentionName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[GeoCodeFlag] [bit] NOT NULL CONSTRAINT [DF_AddressHistory_GeoCodeFlag] DEFAULT ((0)),
[GeoCodeMatch] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Latitude] [decimal] (18, 6) NULL,
[Longitude] [decimal] (18, 6) NULL,
[MSANumber] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Country] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Sieb77AddrID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CountryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_AddressHistory_LogDate] DEFAULT (getdate()),
[RECORDSTAMP] [timestamp] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[PhoneVoice3] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt3] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoice4] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt4] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_AddressHistory_CreatedByIDSeq] DEFAULT ((-1))
) ON [PRIMARY]
GO
ALTER TABLE [customers].[AddressHistory] ADD CONSTRAINT [PK_AddressHistory] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_AddressHistory_RECORDSTAMP] ON [customers].[AddressHistory] ([RECORDSTAMP]) ON [PRIMARY]
GO
