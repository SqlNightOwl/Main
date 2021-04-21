use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[SWCorpACHVerification_vDetail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [sst].[SWCorpACHVerification_vDetail]
GO
setuser N'sst'
GO
CREATE view sst.SWCorpACHVerification_vDetail
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/12/2008
Purpose  :	Wraps the logic for parsing the NACHA file for loading into the
			SWCorpACHVerification table.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	h.FileDate
	,	h.FileType
	,	h.TotalDebit
	,	h.TotalCredit
	,	TxnCode	= cast(substring(d.Record, 2, 2) as tinyint)
	,	RTN		= substring(d.Record, 4, 9)
	,	Account	= rtrim(substring(d.Record, 13, 17))
	,	TaxId	= rtrim(substring(d.Record, 40, 15))
	,	Company	= rtrim(substring(d.Record, 55, 24))
	,	Amount	= cast(substring(d.Record, 30, 10) as money) / 100
	,	RowId	= cast(substring(d.Record, 88, 7) as int)
from	sst.SWCorpACHVerification_load	d
cross join
	(	select	FileDate	= max(case left(Record, 1) when '1' then cast('20' + substring(Record, 24, 6) as int) else null end)
			,	FileType	= max(case left(Record, 1) when '5' then substring(Record, 51, 3) else null end)
			,	TotalDebit	= cast(max(case left(Record, 1) when '8' then substring(Record, 21, 12) else null end) as money) / 100
			,	TotalCredit	= cast(max(case left(Record, 1) when '8' then substring(Record, 33, 12) else null end) as money) / 100
		from	sst.SWCorpACHVerification_load
		where	Record like '1%' or Record like '5%' or Record like '8%'
	)	h
where	Record like '6%';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO