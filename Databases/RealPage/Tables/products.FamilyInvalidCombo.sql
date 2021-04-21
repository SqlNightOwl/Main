CREATE TABLE [products].[FamilyInvalidCombo]
(
[IDSeq] [bigint] NOT NULL IDENTITY(1, 1),
[FirstFamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SecondFamilyCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[DisabledFlag] [int] NOT NULL CONSTRAINT [DF_FamilyInvalidCombo_DisabledFlag] DEFAULT ((0)),
[CreatedByIDSeq] [bigint] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_FamilyInvalidCombo_CreatedDate] DEFAULT (getdate()),
[ModifiedByIDSeq] [bigint] NULL,
[ModifiedDate] [datetime] NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_FamilyInvalidCombo_SystemLogDate] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [products].[FamilyInvalidCombo] ADD CONSTRAINT [PK_FamilyInvalidCombo] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_FamilyInvalidCombo] ON [products].[FamilyInvalidCombo] ([FirstFamilyCode], [SecondFamilyCode], [DisabledFlag]) ON [PRIMARY]
GO
ALTER TABLE [products].[FamilyInvalidCombo] WITH NOCHECK ADD CONSTRAINT [FamilyInvalidCombo_has_FirstFamilyCode] FOREIGN KEY ([FirstFamilyCode]) REFERENCES [products].[Family] ([Code])
GO
ALTER TABLE [products].[FamilyInvalidCombo] WITH NOCHECK ADD CONSTRAINT [FamilyInvalidCombo_has_SecondFamilyCode] FOREIGN KEY ([SecondFamilyCode]) REFERENCES [products].[Family] ([Code])
GO
EXEC sp_addextendedproperty N'MS_Description', N'IDSeq of User creating seed Record', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'CreatedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Created Date of seed Record', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'CreatedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Disabled Status : 0 means Active; 1 means Inactive', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'DisabledFlag'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Primary Family Code', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'FirstFamilyCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Auto Incremented IDSeq;  Primary Key', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'IDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'IDSeq of User who last Modified seed Record', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'ModifiedByIDSeq'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Modified Date of Seed Record', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'ModifiedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'SQL internal recordstamp', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'RECORDSTAMP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Invalid Combo to Primary Family Code', 'SCHEMA', N'products', 'TABLE', N'FamilyInvalidCombo', 'COLUMN', N'SecondFamilyCode'
GO
