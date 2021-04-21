use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[fact_Transaction_stage]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [wh].[fact_Transaction_stage]
GO
CREATE TABLE [wh].[fact_Transaction_stage] (
	[AcctNbr] [bigint] NULL ,
	[CustNbr] [bigint] NULL ,
	[CustTypCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MajorTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[MinorTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[AcctStatCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TxnNbr] [bigint] NULL ,
	[TxnAmt] [money] NULL ,
	[TxnTypCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TxnSourceCd] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[ApplNbr] [bigint] NULL ,
	[TraceNbr] [bigint] NULL ,
	[TxnDescNbr] [bigint] NULL ,
	[BranchNbr] [bigint] NULL ,
	[NetworkNodeNbr] [bigint] NULL ,
	[OrigPostDate] [datetime] NULL ,
	[PostDate] [datetime] NULL ,
	[EffDate] [datetime] NULL ,
	[ActDateTime] [datetime] NULL ,
	[TimeUniqueExtn] [bigint] NULL ,
	[CashBoxNbr] [bigint] NULL ,
	[TellerNbr] [bigint] NULL ,
	[CardTxnNbr] [bigint] NULL ,
	[AgreeNbr] [bigint] NULL ,
	[MemberNbr] [bigint] NULL ,
	[ISOTxnCd] [bigint] NULL ,
	[NetworkCd] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[TerminalId] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[row] [int] IDENTITY (1, 1) NOT NULL ,
	CONSTRAINT [PK_fact_Transaction_stage] PRIMARY KEY  CLUSTERED 
	(
		[row]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [ix_transactions] ON [wh].[fact_Transaction_stage]([EffDate], [AcctNbr], [TxnNbr]) ON [PRIMARY]
GO