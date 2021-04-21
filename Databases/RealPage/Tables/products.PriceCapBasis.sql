CREATE TABLE [products].[PriceCapBasis]
(
[Code] [char] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[Name] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [products].[PriceCapBasis] ADD CONSTRAINT [PK_PriceCapBasis] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_PriceCapBasis_RECORDSTAMP] ON [products].[PriceCapBasis] ([RECORDSTAMP]) ON [PRIMARY]
GO
