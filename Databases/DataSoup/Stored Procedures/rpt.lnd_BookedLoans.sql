use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[lnd_BookedLoans]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[lnd_BookedLoans]
GO
setuser N'rpt'
GO
CREATE procedure rpt.lnd_BookedLoans
	@FromDate		datetime
,	@ToDate			datetime
,	@DepartmentID	int			= null
,	@Product		varchar(50)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Rick Davis
Created  :	09/15/2006
Purpose  :	
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/23/2006	Neelima G		Set Book Financed amount to zero for listed Product
							Options Id's.
06/17/2008	Paul Hunter		Moved to SQL 2005.
05/26/2009	Paul Hunter		Moved reference to the legacy Member table.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set	@ToDate		= dateadd(day, 1, @ToDate);
set	@Product	= nullif(rtrim(@Product), '');

select	d.DeptName								as Department
	,	e.Name									as Employee
	,	m.MemberNumber
	,	m.MemberName
	,	a.ApplID
	,	a.LoanNumber
	,	p.ProductName							as Product
	,	coalesce(o.Description, p.ProductName)	as ProductDesc
	,	a.InterviewDate
 	,	case
		when o.ProductOptionsId in (28649579, 28649580, 28649581, 28649581, 22974243, 22974244
								,	22974245, 22974246, 22974247, 22974248, 23055128, 23055129) then 0
		else a.BookFinanced end					as BookFinanced
	,	adb.Complete
	,	case lab.DepartmentID
		when 262 then 'Direct'
		when 263 then 'Indirect'
		else od.DeptName end					as LendingSource
from	legacy.Member				m
join	Legacy.ep.LoanApplication	a
		on	m.MemberID = a.MemberID
join	Legacy.ep.Product			p
		on	a.ProductID = p.ProductID
join	Legacy.ep.LoanActionData	ado
		on	a.ApplID = ado.ApplID
join	Legacy.ep.LoanAction		lao
		on	ado.LoanActionID	= lao.LoanActionID
		and	'Originated By'		= lao.Name
join	Legacy.ep.LoanActionData	adb
		on	a.ApplID = adb.ApplID
join	Legacy.ep.LoanAction		lab
		on	adb.LoanActionID	= lab.LoanActionID
		and	'Booked By'			= lab.Name
join	Legacy.ep.Department		d
		on	ado.DepartmentID = d.DepartmentID
join	Legacy.ep.Employee			e
		on	ado.EmployeeID = e.EmployeeID
join	Legacy.ep.Department		od
		on	a.OrginDept = od.DepartmentID
left join
		Legacy.ep.ProductOptions	o
		on	a.ProductID			= o.ProductID
		and	a.ProductOptionID	= o.ProductOptionsID
where	adb.Complete	between @FromDate and @ToDate
and	(	p.ProductName	= @Product		or @Product			is null)
and	(	a.OrginDept		= @DepartmentID	or @DepartmentID	is null);
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO