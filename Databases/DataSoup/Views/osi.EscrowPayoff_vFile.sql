use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowPayoff_vFile]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[EscrowPayoff_vFile]
GO
setuser N'osi'
GO
CREATE view osi.EscrowPayoff_vFile
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/01/2008
Purpose  :	Used to produces the reconfigured Escrow Payoff Statement report by
			only returning statements where the total is greater than zero.
			This is produced using the bcp command
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	r.Record
	,	r.Row
from	osi.EscrowPayoff	r
join(	select	t.Page
		from(	select	Page
					,	LineTotal	= abs(cast(substring(Record, 20, 6) as money))
									+ abs(cast(substring(Record, 40, 6) as money))
									+ abs(cast(substring(Record, 79, 6) as money))
				from	osi.EscrowPayoff
				where	charindex('-', Record) = 3
			)	t
		group by t.Page
		having sum(t.LineTotal) > 0	)	x
		on	r.Page = x.Page;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO