use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial07Mortgage_vChange]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Colonial07Mortgage_vChange]
GO
setuser N'osi'
GO
CREATE view osi.Colonial07Mortgage_vChange
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/05/2008
Purpose  :	Compares the current and prior osi.Colonial07Mortgage data to generate
			the base list of data for the change script.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	Period		= (select max(Period) from osi.Colonial07Mortgage)
	,	c.Action
	,	c.UserFieldCd
	,	c.InvestorNum
	,	c.LoanNumber
	,	c.MortgagorTaxId
	,	c.Mortgagor
	,	c.CoMortgagorTaxId
	,	c.CoMortgagor
	,	SQLScript	=	case c.Action
						when 'delete' then	'delete osiBank.PersUserField where UserFieldCd = ''COLN'' '
										+	'and PersNbr = ' + cast(o.PersNbr as varchar) + ';'
						when 'insert' then	'insert into osiBank.PersUserField (PersNbr, Value, UserFieldCd, DateLastMaint) '
										+	'values (' + cast(o.PersNbr as varchar) 
										+	', ''' + c.UserFieldCd + ''', ''COLN'', sysdate);'
						else '' end
from	openquery(OSI, 'select PersNbr, cast(TaxId as char(9)) TaxId from osiBank.ViewPersTaxId')	o 
join
	(	--	this view represents the total change in accounts
		select	isnull(p.LoanNum, c.LoanNum)										as LoanNumber
			,	isnull(p.InvestorNum, c.InvestorNum)								as InvestorNum
			,	isnull(p.MortgagorTaxId, c.MortgagorTaxId)							as MortgagorTaxId
			,	isnull(p.MortgagorFullName, c.MortgagorFullName)					as Mortgagor
			,	nullif(isnull(p.CoMortgagorTaxId, c.CoMortgagorTaxId), '000000000')	as CoMortgagorTaxId
			,	isnull(p.CoMortgagorFullName, c.CoMortgagorFullName)				as CoMortgagor
			,	case isnull(p.InvestorNum, c.InvestorNum)	
				when '3614' then 'R' else 'Z' end									as UserFieldCd
			,	case
				when len(coalesce(p.InvestorNum, c.InvestorNum, '')) = 0 then 'not found'
				when len(p.InvestorNum) > 0 then 'delete'
				when len(c.InvestorNum) > 0 then 'insert'
				else '' end															as Action
		from(	--	 collect the prior period data
				select	LoanNum
					,	InvestorNum
					,	MortgagorTaxId
					,	MortgagorFullName
					,	CoMortgagorTaxId
					,	CoMortgagorFullName
				from	osi.Colonial07Mortgage
				where	Period = (select min(Period) from osi.Colonial07Mortgage)
			)	p
		full outer join
			(	--	 collect the new current period data
				select	LoanNum
					,	InvestorNum
					,	MortgagorTaxId
					,	MortgagorFullName
					,	CoMortgagorTaxId
					,	CoMortgagorFullName
				from	osi.Colonial07Mortgage
				where	Period = (select max(Period) from osi.Colonial07Mortgage)
			)	c	on	p.MortgagorTaxId = c.MortgagorTaxId
		where	p.MortgagorTaxId is null
			or	c.MortgagorTaxId is null
	)	c	on	o.TaxId = c.MortgagorTaxId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO