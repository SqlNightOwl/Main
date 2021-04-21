use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[AlertBalance_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [ihb].[AlertBalance_v]
GO
setuser N'ihb'
GO
CREATE view ihb.AlertBalance_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/11/2006
Purpose  :	Used to product the IHB Alert Balance Response file for Corillian.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/22/2007	Paul Hunter		Changed to use the OSI database to pull balances.
10/04/2007	Paul Hunter		Moved to tcuDataSoup
04/17/2008	Paul Hunter		Recreated as a view so that it can be exported using
							the BCP process.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	a.RecordId
	,	case
		a.RecordType
		when 0	then	left(a.Record, 16)
					+	c.TransactionDate	-- Transaciton Date & Time
					+	replace(convert(varchar(8), getdate(), 14), ':', '')
		when 10	then	cast(a.Record as char(63))
					+	case a.Balance when null then 'X' else 'B' end
					+	case when a.Balance < 0 then '-' else '0' end
					+	tcu.fn_lpadc(cast(abs(a.Balance) as varchar(15)), 15, '0')
					+	c.TransactionDate + '000000'
					+	'000000000000.00'					--	Unsigned Transaction Amount
						--	Transaction Type (15), Reference Number (10) and Description (40)
					+	space(65)
		when 99	then	'99' + tcu.fn_zeropad(c.Items, 10) 
		else ''	end		as Record
from	ihb.Alert	a
join(	select	AlertType
			,	count(1)	as Items
			,	convert(char(8), getdate(), 112) as TransactionDate
		from	ihb.Alert
		where	AlertType		= 'BAL'
		and		RecordType		= 10
		and		AccountNumber	> 0
		group by AlertType
	)	c	on	a.AlertType = c.AlertType
where	a.AlertType		=	'BAL'	--	balance request
and	( (	a.RecordType	!=	10 )	--	header/footer
	or(	a.RecordType	=	10 and	--	detail w/accounts
		a.AccountNumber	>	0	));
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO