use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[lnd_ColonialMaintenance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[lnd_ColonialMaintenance]
GO
setuser N'rpt'
GO
CREATE procedure rpt.lnd_ColonialMaintenance
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/03/2007
Purpose  :	Identifies changes to \Colonial Loans that were added/removed between
			two periods.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

exec ops.SSRSReportUsage_ins @@procid

declare 
    @currentPeriod	int 
,	@previousPeriod	int 

--set @currentPeriod =  cast(convert(char(6), getdate(), 112) as int)
set @currentPeriod	= cast(convert(char(6), dateadd(month, -1, getdate()), 112) as int)
set @previousPeriod = cast(convert(char(6), dateadd(month, -2, getdate()), 112) as int)

if	exists(	select top 1 MortgagorTaxID from Legacy.me.Colonial07Mortgage
			where Period = @currentPeriod	)
and	exists(	select top 1 MortgagorTaxID	from Legacy.me.Colonial07Mortgage
			where Period = @previousPeriod	)
begin
	-- Present only in the previous period
	select	InvestorNum			= coalesce(c.InvestorNum		, p.InvestorNum)
		,	c.InvestorCode
    	,	MortgagorTaxID		= coalesce(c.MortgagorTaxID		, p.MortgagorTaxID)
    	,	MortgagorFullName	= coalesce(c.MortgagorFullName	, p.MortgagorFullName)
    	,	CoMortgagorTaxID	= nullif(coalesce(c.CoMortgagorTaxID	, p.CoMortgagorTaxID), '000000000')
    	,	CoMortgagorFullName	= coalesce(c.CoMortgagorFullName, p.CoMortgagorFullName)
		,	MortgagorType		= case when c.InvestorNum is null then 'Removed' else 'Added' end
	from(	select	Period
				,	InvestorNum
				,	InvestorCode	= case InvestorNum when '3614' then 'R' else 'Z' end
				,	MortgagorTaxID
				,	MortgagorFullName
				,	CoMortgagorTaxID
				,	CoMortgagorFullName
			from	Legacy.me.Colonial07Mortgage
			where	Period = @currentPeriod
		)	c
	full outer join
		(	select	Period
				,	InvestorNum
		    	,	MortgagorTaxID
		    	,	MortgagorFullName
		    	,	CoMortgagorTaxID
		    	,	CoMortgagorFullName
			from	Legacy.me.Colonial07Mortgage with (nolock)
			where	Period = @previousPeriod
		)	p	on c.MortgagorTaxID = p.MortgagorTaxID
	where	c.MortgagorTaxID	is null
	or		p.MortgagorTaxID	is null
	order by
			coalesce(p.Period, c.Period)
		,	coalesce(p.MortgagorFullName, c.MortgagorFullName)
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO