use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfIsiTransaction]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [osi].[tfIsiTransaction]
GO
CREATE TABLE [osi].[tfIsiTransaction] (
	[AcctNbr] [bigint] NOT NULL ,
	[RtxnNbr] [int] NOT NULL ,
	[PersNbr] [int] NOT NULL 
) ON [PRIMARY]
GO
 CREATE  CLUSTERED  INDEX [CX_tf_IsiTransaction] ON [osi].[tfIsiTransaction]([AcctNbr], [RtxnNbr]) ON [PRIMARY]
GO
 CREATE  INDEX [IX_PersNbr] ON [osi].[tfIsiTransaction]([PersNbr]) ON [PRIMARY]
GO