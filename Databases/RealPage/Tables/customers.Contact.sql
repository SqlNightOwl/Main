CREATE TABLE [customers].[Contact]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ContactTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[FirstName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[LastName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Salutation] [char] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Title] [char] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AddressIDSeq] [int] NULL,
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreateDate] [datetime] NOT NULL CONSTRAINT [DF_Contact_CreateDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_Contact_ModifiedDate] DEFAULT (getdate()),
[PortalUserStatus] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Contact_UserStatus] DEFAULT ('ACTIVE'),
[ConfirmationCode] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PortalLastLoginDate] [datetime] NULL,
[ContactEmail] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Contact_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Contact_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Contact_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [customers].[Contact] ADD CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Contact_RECORDSTAMP] ON [customers].[Contact] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[Contact] WITH NOCHECK ADD CONSTRAINT [Contact_has_CompanyIDSeq] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[Contact] WITH NOCHECK ADD CONSTRAINT [Contact_has_ContactType] FOREIGN KEY ([ContactTypeCode]) REFERENCES [customers].[ContactType] ([Code])
GO
ALTER TABLE [customers].[Contact] WITH NOCHECK ADD CONSTRAINT [Contact_has_PropertyIDSeq] FOREIGN KEY ([PropertyIDSeq]) REFERENCES [customers].[Property] ([IDSeq])
GO
