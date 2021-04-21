use DataSoup
go
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOffJointOwner]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [risk].[ChargeOffJointOwner]
GO
CREATE TABLE [risk].[ChargeOffJointOwner] (
	[AccountNumber] [bigint] NOT NULL ,
	[JointOwner] [int] NOT NULL ,
	CONSTRAINT [PK_ChargeOffJointOwner] PRIMARY KEY  CLUSTERED 
	(
		[AccountNumber],
		[JointOwner]
	)  ON [PRIMARY] 
) ON [PRIMARY]
GO
 CREATE  INDEX [IX_JointOwner] ON [risk].[ChargeOffJointOwner]([JointOwner]) ON [PRIMARY]
GO