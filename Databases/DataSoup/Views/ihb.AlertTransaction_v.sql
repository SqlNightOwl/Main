use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[AlertTransaction_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [ihb].[AlertTransaction_v]
GO
setuser N'ihb'
GO
CREATE view ihb.AlertTransaction_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/11/2006
Purpose  :	Used to product the IHB Alert Transaction Response file for Corillian.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/24/2007	Paul Hunter		Changed to use OSI transactions.
10/04/2007	Paul Hunter		Moved to tcuDataSoup
03/11/2008	Paul Hunter		Changed OSI query to use openquery syntax instead of
							[DB]..[schema].[object] syntax.
04/17/2008	Paul Hunter		Recreated as a view so that it can be exported using
							the BCP process.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	RecordId
	,	case RecordType
		when 0	then	left(Record, 16) + ReportDate
					+	replace(convert(varchar(8), getdate(), 14), ':', '')
		when 99	then	'99' + tcu.fn_zeropad(c.Items, 10)
		else '' end		as Record
from	ihb.Alert	a
join(	select	a.AlertType
			,	count(1) as Items
			,	convert(char(8), getdate(), 112) as ReportDate
		from	ihb.Alert				a
		join	ihb.AlertTransaction	t
				on	a.AccountNumber	= t.AcctNbr
		where	a.AlertType	= 'TRN'
		group by a.AlertType
	)	c	on	a.AlertType = c.AlertType
where	a.AlertType		=	'TRN'
and		a.RecordType	!=	10

union all

select	a.RecordId
	,	cast(Record as char(63))
	+	case
		when left(t.RtxnTypCd , 3) = 'CLS' then 'X'
		when t.TranAmt < 0 then 'D'
		else 'C' end								--	Trans Code
	+	'0000000000000.00'							--	Balance
	+	left(replace(replace(replace(
			convert(varchar, t.ActDateTime, 121)
			, ':', ''), '-', ''), ' ', ''), 14)		--	Trans Date
	+	tcu.fn_lpadc(cast(abs(t.TranAmt) as varchar(15)), 15, '0')	--	Unsigned Transaction Amount
	+	t.Description								--	TransactionType
	+	space(50)	as Record						--	Reference Number (10) & Description (40)
from	ihb.Alert				a
join	ihb.AlertTransaction	t
		on	a.AccountNumber	= t.AcctNbr
where	a.AlertType		= 'TRN'
and		a.RecordType	= 10
and		a.AccountNumber	> 0;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO