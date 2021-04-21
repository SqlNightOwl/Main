use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire_vWire]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[BankServWire_vWire]
GO
setuser N'sst'
GO
CREATE view sst.BankServWire_vWire
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/23/2008
Purpose  :	Transforms the Business Banking BankServ wires request into the
			initial BankServWire record (WTX = wire transfer).
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	WireId			= cast(rtrim(substring(Record, 6, 4)) as smallint)
	,	FileDate		= cast(substring(Record, 96, 8) as int)
	,	Amount			= cast(substring(Record, 33, 13) as money) / 100
	,	SenderAccount	= rtrim(substring(Record, 22, 11))
	,	ReceiverName	= rtrim(substring(Record, 126, 23))
	,	ReceiverBank	= rtrim(substring(Record, 898, 36))
	,	ReceiverAccount	= rtrim(substring(Record, 111, 15))
from	sst.BankServWire_load
where	RecordType	= 'WTX';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO