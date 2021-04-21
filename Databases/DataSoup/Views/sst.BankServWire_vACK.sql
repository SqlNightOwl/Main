use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire_vACK]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[BankServWire_vACK]
GO
setuser N'sst'
GO
CREATE view sst.BankServWire_vACK
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/23/2008
Purpose  :	Transforms the Business Banking BankServ wires ACK response into the
			a ibb_BankServWire record (ACK = Acknowledgement).
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	WireId	= cast(rtrim(substring(Record, 14, 4)) as smallint)
	,	IMAD	= rtrim(substring(Record, 71, 22))
from	sst.BankServWire_load
where	RecordType	= 'ACK';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO