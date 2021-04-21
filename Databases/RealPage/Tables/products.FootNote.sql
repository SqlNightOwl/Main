CREATE TABLE [products].[FootNote]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[Title] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Description] [varchar] (4000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyTo] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ApplyToProductCategory] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[MandatoryFlag] [bit] NOT NULL CONSTRAINT [DF_PRODUCTS_FootNote] DEFAULT ((0)),
[ActiveFlag] [bit] NOT NULL CONSTRAINT [DF_PRODUCTS_ActiveFlag] DEFAULT ((1)),
[RECORDSTAMP] [timestamp] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_FootNote_CreatedDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_FootNote_CreatedByIDSeq] DEFAULT ((-1)),
[ModifiedDate] [datetime] NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_FootNote_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[FootNote] ADD CONSTRAINT [PK_FootNote] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_FootNote_RECORDSTAMP] ON [products].[FootNote] ([RECORDSTAMP]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [INCX_FootNote_Title] ON [products].[FootNote] ([Title]) ON [PRIMARY]
GO
